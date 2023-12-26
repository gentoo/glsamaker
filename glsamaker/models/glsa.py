from datetime import datetime
from typing import List, Tuple

from envelope import Envelope
from flask import current_app as app
from flask import render_template
from sqlalchemy.orm import Mapped, relationship
from sqlalchemy.orm.query import Query
from tabulate import tabulate

from glsamaker.app import config
from glsamaker.extensions import base, db
from glsamaker.glsarepo import GLSARepo
from glsamaker.models.bug import Bug
from glsamaker.models.package import Affected
from glsamaker.models.reference import Reference
from glsamaker.models.user import User


class GLSA(base):
    __tablename__ = "glsa"

    id = db.Column(db.Integer(), primary_key=True)
    glsa_id = db.Column(db.String(), unique=True)
    draft = db.Column(db.Boolean())
    title = db.Column(db.String())
    synopsis = db.Column(db.String())
    product_type = db.Column(db.Enum("ebuild", "infrastructure", name="product_types"))
    product = db.Column(db.String())
    announced = db.Column(db.Date())
    revision_count = db.Column(db.Integer())
    revised_date = db.Column(db.Date())
    bugs: Mapped[list[Bug]] = relationship("Bug", secondary="glsa_to_bug")
    # TODO: lots of variation here, we should cleanup eventually
    access = db.Column(
        db.Enum(
            "unknown",
            "local",
            "remote",
            "local, remote",
            "remote, local",
            "local and remote",
            # glsa-200503-10
            "remote and local",
            # glsa-200311-0{1,2}
            "local / remote",
            # glsa-200403-01
            "local and remote combination",
            # glsa-201001-03, glsa-201011-01
            "local remote",
            # glsa-200408-18
            "remote root",
            # glsa-200401-04
            "man-in-the-middle",
            # glsa-200312-01
            "",
            name="access_types",
        )
    )
    affected: Mapped[list[Affected]] = relationship(
        "Affected", secondary="glsa_to_affected"
    )
    background = db.Column(db.String())
    description = db.Column(db.String())
    impact_type = db.Column(
        db.Enum("minimal", "low", "medium", "normal", "high", name="impact_types")
    )
    impact = db.Column(db.String())
    workaround = db.Column(db.String())
    resolution = db.Column(db.String())
    references: Mapped[List[Reference]] = relationship(
        "Reference", secondary="glsa_to_ref"
    )
    # TODO: bugReady metadata tag?
    requester = db.Column(db.Integer, db.ForeignKey(User.id))
    submitter = db.Column(db.Integer, db.ForeignKey(User.id))
    acked_by = db.Column(db.Integer, db.ForeignKey(User.id))
    requested_time = db.Column(db.DateTime())
    submitted_time = db.Column(db.DateTime())

    committed = db.Column(db.Boolean())

    @classmethod
    def next_id(cls):
        now = datetime.now()
        date = "{}{:02}".format(now.year, now.month)
        query = db.session.query(cls).filter(cls.glsa_id.startswith(date)).all()
        n = 1
        if query:
            ids = [int(x.glsa_id.split("-")[1]) for x in query]
            n = max(ids) + 1
        return "{}-{:02}".format(date, n)

    def get_references(self) -> list[Reference]:
        # Join References with glsa_to_ref to find which references
        # are in the GLSA (`self`), so we can return the list of
        # references ordered by the reference text.
        references = (
            db.session.query(Reference)
            .filter(
                glsa_to_ref.columns.ref_text == Reference.ref_text,
                glsa_to_ref.columns.glsa_id == self.glsa_id,
            )
            .order_by(Reference.ref_text)
            .all()
        )
        return sorted(references)

    def get_reference_texts(self) -> list[str]:
        return [ref.ref_text for ref in self.get_references()]

    def get_bugs(self) -> list[str]:
        items = (
            db.session.query(Bug.bug_id)
            .join(glsa_to_bug)
            .filter(glsa_to_bug.columns.glsa_id == self.glsa_id)
            .order_by(Bug.bug_id)
            .distinct()
            .all()
        )

        # above query returns a structure of list[Tuple[str,]], prune that down
        return [item[0] for item in items]

    def get_bugs_links(self) -> list[str]:
        lst = []
        link = '<a href="https://bugs.gentoo.org/BUG" title="Bug BUG" target="_blank" rel="noopener">BUG</a>'

        for bug in self.get_bugs():
            x = link.replace("BUG", bug)
            lst.append(x)
        return lst

    def get_pkgs(self) -> list[str]:
        return sorted(list(set([pkg.pkg for pkg in list(self.affected)])))

    def get_affected_arch(self, pn):
        ret = set()
        for pkg in [pkg for pkg in self.affected if pkg.pkg == pn]:
            ret.add(pkg.arch)
        if len(ret) > 1:
            app.logger.error(
                "Something has gone horribly wrong with GLSA {}!".format(self.id)
            )
            app.logger.error("{} has multiple arches: {}".format(pkg, ret))
        return list(ret)[0].replace(",", " ")

    def get_affected_for_pkg(self, pn) -> list[Affected]:
        return list(filter(lambda x: x.pkg == pn, self.affected))

    def get_unaffected(self) -> list[Affected]:
        return list(filter(lambda x: x.range_type == "unaffected", self.affected))

    def get_vulnerable(self) -> list[Affected]:
        return list(filter(lambda x: x.range_type == "vulnerable", self.affected))

    @property
    def resolution_xml(self) -> list[str]:
        lines = self.resolution.splitlines()
        ret = []
        in_code = False

        # TODO: need to handle multiple lines that should be wrapped
        # in the same <p>
        for line in lines:
            line = line.strip()
            if line.startswith("#") and not in_code:
                ret += ["<code>"]
                ret += ["  " + line]
                in_code = True
            elif not line.startswith("#") and in_code:
                if line:
                    ret += ["  " + line]
                ret += ["</code>"]
                ret += [""]
                in_code = False
            elif line.startswith("#") and in_code:
                ret += ["  " + line]
            elif line:
                ret += ["<p>" + line + "</p>"]
                ret += [""]

        if in_code:
            ret += ["</code>"]

        # Get rid of trailing empty list member
        if not ret[-1]:
            ret.pop()
        return ret

    @property
    def resolution_text(self) -> str:
        lines = self.resolution.splitlines()
        ret = []

        for line in lines:
            line = line.strip()
            if line.startswith("#"):
                ret += ["  " + line]
            else:
                ret += [line]
        return "\n".join(ret)

    def _get_package_slots(self, package: str) -> list[str]:
        return (
            db.session.query(Affected.slot)
            .filter(
                glsa_to_affected.columns.affected_id == Affected.affected_id,
                glsa_to_affected.columns.glsa_id == self.glsa_id,
                Affected.pkg == package,
            )
            .distinct()
            .all()
        )

    def _generate_mail_table_row(
        self,
        vulnerable_query: Query[Affected],
        unaffected_query: Query[Affected],
        include_package: bool = True,
        slot: str = "",
    ) -> Tuple[str, str, str]:
        if slot:
            vulnerable_query = vulnerable_query.filter(Affected.slot == slot)
            unaffected_query = unaffected_query.filter(Affected.slot == slot)

        vulnerable_versions = vulnerable_query.all()
        unaffected_versions = unaffected_query.all()

        # the caller should ensure that there's only one package in
        # the queries that we're fed here
        # if not - problem!
        pkgs = {affected.pkg for affected in vulnerable_versions + unaffected_versions}

        if len(pkgs) != 1:
            raise RuntimeError

        if len(vulnerable_versions) > 0:
            vulnerable_versionstr = "{} {}".format(
                Affected.range_types_rev[vulnerable_versions[0].pkg_range],
                vulnerable_versions[0].version,
            )
            if slot:
                vulnerable_versionstr += ":{}".format(slot)
        else:
            vulnerable_versionstr = ""

        if len(unaffected_versions) > 0:
            unaffected_versionstr = "{} {}".format(
                Affected.range_types_rev[unaffected_versions[0].pkg_range],
                unaffected_versions[0].version,
            )
            if slot:
                unaffected_versionstr += ":{}".format(slot)
        else:
            unaffected_versionstr = "Vulnerable!"

        return (
            list(pkgs)[0] if include_package else "",
            vulnerable_versionstr,
            unaffected_versionstr,
        )

    def generate_mail_table(self) -> str:
        headers = ["Package", "Vulnerable", "Unaffected"]
        table = []

        for package in sorted(self.get_pkgs()):
            vulnerable_versions_query = (
                db.session.query(Affected)
                .join(glsa_to_affected)
                .filter(
                    Affected.pkg == package,
                    Affected.range_type == "vulnerable",
                    glsa_to_affected.columns.glsa_id == self.glsa_id,
                )
            )

            unaffected_versions_query = (
                db.session.query(Affected)
                .join(glsa_to_affected)
                .filter(
                    Affected.pkg == package,
                    Affected.range_type == "unaffected",
                    glsa_to_affected.columns.glsa_id == self.glsa_id,
                )
            )

            package_slots = self._get_package_slots(package)
            if len(package_slots) > 1:
                # track which packages have been added to the table so we know
                # whether we need to add the cat/pkg to the first ("package")
                # column
                added_pkgs = set()
                for slot in package_slots:
                    table.append(
                        self._generate_mail_table_row(
                            vulnerable_versions_query,
                            unaffected_versions_query,
                            package not in added_pkgs,
                            slot=slot[0],
                        )
                    )

                    added_pkgs.update([package])
            else:
                table.append(
                    self._generate_mail_table_row(
                        vulnerable_versions_query, unaffected_versions_query
                    )
                )

        return tabulate(table, headers=headers)

    def generate_xml(self) -> str:
        return render_template("glsa.xml", glsa=self)

    def generate_mail_text(self) -> str:
        return render_template("glsa.mail", glsa=self)

    def generate_mail(
        self,
        date=None,
        smtpuser=None,
        replyto=None,
        smtpto=None,
        gpg_home=None,
        gpg_pass=None,
        signing_key=None,
    ) -> Envelope:
        rendered = self.generate_mail_text()

        message = (
            Envelope(rendered)
            .subject(f"[ GLSA {self.glsa_id} ] {self.title}")
            .reply_to(replyto or smtpuser)
            # TODO: Without this, and with jinja's trim_blocks,
            # Envelope will changing the encoding of the mail and
            # switch "=" for "=3D"
            .header("Content-Type", 'text/plain; charset="utf-8"')
        )

        message = message.from_(smtpuser)
        if smtpto:
            message = message.to(smtpto)
        if date:
            message = message.date(date)
        if gpg_home and gpg_pass and signing_key:
            # gnugp is not a typo, envelope's argument name is just
            # mispelled.
            message = message.gpg(gnugp_home=gpg_home).signature(
                passphrase=gpg_pass, key=signing_key
            )
        return message

    def release_email(self) -> None:
        server = (
            config["glsamaker"]["smtpserver"]
            if "smtpserver" in config["glsamaker"]
            else None
        )
        smtpuser = (
            config["glsamaker"]["smtpuser"]
            if "smtpuser" in config["glsamaker"]
            else None
        )
        smtppass = (
            config["glsamaker"]["smtppass"]
            if "smtppass" in config["glsamaker"]
            else None
        )
        smtpto = config["glsamaker"]["smtpto"]
        replyto = config["glsamaker"]["replyto"]
        gpg_home = config["glsamaker"]["gpg_home"]
        gpg_pass = config["glsamaker"]["gpg_pass"]
        signing_key = config["glsamaker"]["signing_key"]
        mail = self.generate_mail(
            date=datetime.now().strftime("%a, %d %b %Y %X"),
            smtpuser=smtpuser,
            replyto=replyto,
            smtpto=smtpto,
            gpg_home=gpg_home,
            gpg_pass=gpg_pass,
            signing_key=signing_key,
        )

        if not smtppass:
            app.logger.info(f"sending mail unauthed to {server}")
            mail = mail.smtp(host=server)
            mail._smtp.instance = mail._smtp.connect()
            sent = mail.send()
        else:
            app.logger.info(f"sending mail to {server}")
            sent = mail.smtp(server, 587, smtpuser, smtppass, "starttls").send()

        if bool(sent):
            app.logger.info(f"Sent mail for {self.glsa_id}")
        else:
            app.logger.info(f"Failed sending mail for {self.glsa_id}")

        app.logger.info(f"Message-ID: {sent.as_message()['Message-ID']}")

    def release(self) -> None:
        glsarepo = GLSARepo(
            "/var/lib/glsamaker/glsa",
            config["glsamaker"]["gpg_pass"],
            config["glsamaker"]["gpg_home"],
            ssh_key=config["glsamaker"]["ssh_key"],
            signing_key=config["glsamaker"]["signing_key"],
        )
        if not self.committed:
            glsarepo.commit(self)
            self.committed = True
        glsarepo.push()
        self.release_email()


glsa_to_bug = db.Table(
    "glsa_to_bug",
    base.metadata,
    db.Column(
        "glsa_id", db.String(), db.ForeignKey("glsa.glsa_id", onupdate="cascade")
    ),
    db.Column("bug_id", db.String(), db.ForeignKey("bug.bug_id", onupdate="cascade")),
)

glsa_to_ref = db.Table(
    "glsa_to_ref",
    base.metadata,
    db.Column(
        "glsa_id", db.String(), db.ForeignKey("glsa.glsa_id", onupdate="cascade")
    ),
    db.Column(
        "ref_text", db.String(), db.ForeignKey("reference.ref_text", onupdate="cascade")
    ),
)

glsa_to_affected = db.Table(
    "glsa_to_affected",
    base.metadata,
    db.Column(
        "glsa_id", db.String(), db.ForeignKey("glsa.glsa_id", onupdate="cascade")
    ),
    db.Column(
        "affected_id",
        db.Integer(),
        db.ForeignKey("affected.affected_id", onupdate="cascade"),
    ),
)
