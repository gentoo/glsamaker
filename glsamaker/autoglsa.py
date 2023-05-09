import itertools
import re
import uuid
from datetime import datetime
from typing import Dict

import bracex
from bugzilla.bug import Bug as BugzillaBug
from flask import current_app as app
from pkgcore.ebuild import atom as atom_mod
from pkgcore.ebuild.atom import atom as Atom
from pkgcore.ebuild.errors import InvalidCPV

from glsamaker.app import bgo
from glsamaker.extensions import db
from glsamaker.models.bug import Bug
from glsamaker.models.glsa import GLSA
from glsamaker.models.package import Affected
from glsamaker.models.reference import Reference

LEGAL_WHITEBOARDS = [str(x) + str(y) for x in "ABC~" for y in "01234"]

MULTI_DESCRIPTION = (
    "Multiple vulnerabilities have been discovered in {}. "
    "Please review the CVE identifiers referenced below for details."
)
RESOLUTION = """
All {} users should upgrade to the latest version:

# emerge --sync
# emerge --ask --oneshot --verbose "{}"
""".strip()
IMPACT = "Please review the referenced CVE identifiers for details."


class IllegalBugException(Exception):
    pass


class FirstGlsaException(Exception):
    pass


def validate_bugs(bugs: list[BugzillaBug]):
    whiteboards = [bug.whiteboard for bug in bugs]
    products = [bug.product for bug in bugs]
    components = [bug.component for bug in bugs]
    assignees = [bug.assigned_to for bug in bugs]

    # Collect the bugs that are invalid
    whiteboards = list(
        filter(lambda bug: bug.whiteboard[:2] not in LEGAL_WHITEBOARDS, bugs)
    )
    products = list(filter(lambda bug: bug.product != "Gentoo Security", bugs))
    components = list(filter(lambda bug: bug.component != "Vulnerabilities", bugs))
    assignees = list(
        filter(lambda bug: not bug.assigned_to.startswith("security"), bugs)
    )

    if len(whiteboards) != 0:
        raise IllegalBugException([bug.id for bug in whiteboards])
    if len(products) != 0:
        raise IllegalBugException([bug.id for bug in products])
    if len(components) != 0:
        raise IllegalBugException([bug.id for bug in components])
    if len(assignees) != 0:
        raise IllegalBugException([bug.id for bug in assignees])


def get_max_versions(bugs: list[BugzillaBug]) -> list[Atom]:
    max_versions: Dict[str, Atom] = {}
    for bug in bugs:
        # It's common for people to do things like
        # '<foo/bar-{1.2, 2.2}: blah blah' which expands to
        # '<foo/bar-1.2', '<foo/bar- 2.2', which is invalid
        # This converts it into '<foo/bar-{1.2,2.2}: blah blah' instead.
        summary = re.sub("({.*) (.*})", r"\1\2", bug.summary)

        # The previous regex substitution doesn't quite get all of the
        # cases of a space between brackets when commas are involved,
        # so just sledgehammer the extra space away. Probably a way to
        # do it with re.sub.
        summary = summary.replace(", ", ",")

        # Get the part of the summary with the affected packages,
        # before the :
        summary = summary.split(":")[0]

        # Expand '<foo/bar-{1.2,2.2}' into
        # ['<foo/bar-1.2', '<foo/bar-2.2']
        summaries = bracex.expand(summary)

        # Finally, account for the summaries that start out like
        # '<foo/bar-1.2 <foo/baz-1.3' by splitting each summary in
        # summaries then flattening the resulting list, giving us a
        # clean list of each of the packages in the summary
        summaries = list(itertools.chain(*[x.split() for x in summaries]))

        for summary in summaries:
            try:
                # Hack to ensure atoms beginning with = are treated
                # the way we want them to be. = matters for bug
                # targeting, but generally not for GLSAs, since we
                # generally want people to upgrade unconditionally.
                # See also the apache test for this.
                package = summary.replace("=", "<")
                atom = atom_mod.atom(package)
                unversioned_atom = str(atom.unversioned_atom)
                if unversioned_atom in max_versions:
                    max_versions[unversioned_atom] = max(
                        atom, max_versions[unversioned_atom]
                    )
                else:
                    max_versions[unversioned_atom] = atom
            except InvalidCPV:
                # Not fatal if a summary is screwed up enough to fail
                # out here, we'll be able to figure things out when we
                # edit the GLSA.
                app.logger.info("Encountered an autoglsa failure on bug: " + bug.id)
                app.logger.info("Summaries: " + str(summaries))
                app.logger.info("Summary: " + summary)
                app.logger.info("Package: " + package)
    return list(max_versions.values())


def generate_affected(atoms: list[atom_mod.atom]) -> list[Affected]:
    ret = []
    # This isn't able to figure out multiple branches, it will have to
    # be done manually.
    for atom in atoms:
        ret.append(
            Affected(
                str(atom.unversioned_atom),
                atom.fullver,
                Affected.range_types[atom.op],
                "*",
                atom.slot,
                "vulnerable",
            )
        )
        if atom.op == "<":
            ret.append(
                Affected(
                    str(atom.unversioned_atom),
                    atom.fullver,
                    Affected.range_types[">="],
                    "*",
                    atom.slot,
                    "unaffected",
                )
            )
    return ret


def bugs_aliases(bugs):
    ret = []
    bugs = bgo.getbugs(bugs)
    for bug in bugs:
        if bug.blocks:
            ret += list(set(bugs_aliases(bug.blocks)))
            app.logger.info("Found {} in blocking bug {}".format(ret, bug.id))
    return list(set(sorted(ret + [alias for bug in bugs for alias in bug.alias])))


# Would be nicer to make a type of the enum this is used for, rather
# than the return type being just str
def glsa_impact(bugs: list[BugzillaBug]) -> str:
    worst = "{}{}".format(
        min([bug.whiteboard[0] for bug in bugs]),
        min([bug.whiteboard[1] for bug in bugs]),
    )
    if worst[1] == "0" or worst[1] == "1" or worst == "A2":
        return "high"
    elif worst in ["A4", "B3", "B4", "C3"]:
        return "low"
    return "normal"


def previous_glsa(pkg: str) -> GLSA:
    # Query the Affected table for rows with the package we're looking
    # for
    affected = db.session.query(Affected).filter(Affected.pkg == pkg).all()

    # If there's none, we've probably never GLSA'd that package before
    if len(affected) == 0:
        raise FirstGlsaException
    return (
        db.session.query(GLSA)
        .filter(GLSA.affected.contains(affected[-1]))
        .order_by(GLSA.id.desc())
        .first()
    )


def generate_resolution(glsa: GLSA, proper_name: str) -> str:
    resolution = ""
    for x in glsa.get_unaffected():
        resolution += RESOLUTION.format(proper_name, x.versioned_atom())
    return resolution


def autogenerate_glsa(bugs: list[BugzillaBug]) -> GLSA:
    app.logger.info("Autogenerating GLSA from bugs: " + str([bug.id for bug in bugs]))
    validate_bugs(bugs)
    glsa = GLSA()
    glsa.glsa_id = str(uuid.uuid4())
    glsa.draft = True
    glsa.requested_time = datetime.now()
    glsa.product_type = "ebuild"

    packages = get_max_versions(bugs)
    glsa.bugs = [Bug.new(str(bug.id)) for bug in bugs]
    aliases = bugs_aliases([bug.bug_id for bug in glsa.bugs])
    glsa.references = [Reference.new(alias) for alias in aliases]
    glsa.affected = generate_affected(packages)
    glsa.impact_type = glsa_impact(bugs)
    glsa.workaround = "There is no known workaround at this time."

    multiple = len(glsa.bugs) > 1 or any(
        ["multiple vulnerabilities" in bug.summary.lower() for bug in bugs]
    )

    try:
        # These are somewhat more speculative than the previous
        last = previous_glsa(str(packages[0].unversioned_atom))
        glsa.product = last.product
        glsa.background = last.background
        proper_name = last.title.split(":")[0]
        glsa.title = proper_name + ": "
        glsa.description = MULTI_DESCRIPTION.format(proper_name)

        glsa.resolution = generate_resolution(glsa, proper_name)
    except FirstGlsaException:
        glsa.title = ", ".join([package.package for package in packages])
        glsa.title += ": "

    if multiple:
        glsa.title += "Multiple Vulnerabilities"
        glsa.impact = IMPACT

    return glsa
