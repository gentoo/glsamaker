from datetime import datetime

from glsamaker.app import app, config, db
from glsamaker.glsarepo import GLSARepo
from glsamaker.models.reference import Reference
from glsamaker.models.user import User

from envelope import Envelope
from flask import render_template


glsa_to_bug = db.Table(
    "glsa_to_bug",
    db.Column(
        "glsa_id", db.String(), db.ForeignKey("glsa.glsa_id", onupdate="cascade")
    ),
    db.Column("bug_id", db.String(), db.ForeignKey("bug.bug_id", onupdate="cascade")),
)

glsa_to_ref = db.Table(
    "glsa_to_ref",
    db.Column(
        "glsa_id", db.String(), db.ForeignKey("glsa.glsa_id", onupdate="cascade")
    ),
    db.Column(
        "ref_text", db.String(), db.ForeignKey("reference.ref_text", onupdate="cascade")
    ),
)

glsa_to_affected = db.Table(
    "glsa_to_affected",
    db.Column(
        "glsa_id", db.String(), db.ForeignKey("glsa.glsa_id", onupdate="cascade")
    ),
    db.Column(
        "affected_id",
        db.Integer(),
        db.ForeignKey("affected.affected_id", onupdate="cascade"),
    ),
)


class GLSA(db.Model):
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
    bugs = db.relationship("Bug", secondary=glsa_to_bug)
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
    affected = db.relationship("Affected", secondary=glsa_to_affected)
    background = db.Column(db.String())
    description = db.Column(db.String())
    impact_type = db.Column(
        db.Enum("minimal", "low", "medium", "normal", "high", name="impact_types")
    )
    impact = db.Column(db.String())
    workaround = db.Column(db.String())
    resolution = db.Column(db.String())
    references = db.relationship("Reference", secondary=glsa_to_ref)
    # TODO: bugReady metadata tag?
    requester = db.Column(db.Integer, db.ForeignKey(User.id))
    submitter = db.Column(db.Integer, db.ForeignKey(User.id))
    acked_by = db.Column(db.Integer, db.ForeignKey(User.id))
    requested_time = db.Column(db.DateTime())
    submitted_time = db.Column(db.DateTime())

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

    def get_references(self):
        # Join References with glsa_to_ref to find which references
        # are in the GLSA (`self`), so we can return the list of
        # references ordered by the reference text.
        references = (
            Reference.query.filter(
                glsa_to_ref.columns.ref_text == Reference.ref_text,
                glsa_to_ref.columns.glsa_id == self.glsa_id,
            )
            .order_by(Reference.ref_text)
            .all()
        )
        return references

    def get_reference_texts(self):
        return [ref.ref_text for ref in self.get_references()]

    def get_bugs(self):
        return [bug.bug_id for bug in self.bugs]

    def get_bugs_links(self):
        lst = []
        link = '<a href="https://bugs.gentoo.org/BUG" title="Bug BUG" target="_blank" rel="noopener">BUG</a>'

        for bug in self.get_bugs():
            x = link.replace("BUG", bug)
            lst.append(x)
        return lst

    def get_pkgs(self):
        return set([pkg.pkg for pkg in self.affected])

    def get_affected_arch(self, pn):
        ret = set()
        for pkg in [pkg for pkg in self.affected if pkg.pkg == pn]:
            ret.add(pkg.arch)
        if len(ret) > 1:
            app.logger.error(
                "Something has gone horribly wrong with GLSA {}!".format(self.id)
            )
            app.logger.error("{} has multiple arches: {}".format(pkg, ret))
        return list(ret)[0]

    def get_affected_for_pkg(self, pn):
        return [pkg for pkg in self.affected if pkg.pkg == pn]

    def get_vulnerable_for_pkg(self, pn):
        return [
            pkg
            for pkg in self.affected
            if pkg.pkg == pn and pkg.range_type == "vulnerable"
        ]

    def get_unaffected_for_pkg(self, pn):
        return [
            pkg
            for pkg in self.affected
            if pkg.pkg == pn and pkg.range_type == "unaffected"
        ]

    def get_unaffected(self):
        return [pkg for pkg in self.affected if pkg.range_type == "unaffected"]

    def get_vulnerable(self):
        return [pkg for pkg in self.affected if pkg.range_type == "vulnerable"]

    @property
    def resolution_xml(self):
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

        return ret

    @property
    def resolution_text(self):
        print(self.resolution)
        lines = self.resolution.splitlines()
        ret = []

        for line in lines:
            line = line.strip()
            if line.startswith("#"):
                ret += ["  " + line]
            else:
                ret += [line]
        return "\n".join(ret)

    def generate_mail_table(self):
        # TODO: Maybe try to do this in jinja. It worked for ruby in
        # glsamakerv2..
        # Probably needs to reorganize this in the db properly, so
        # that we can access glsa -> package -> affected ranges rather
        # than glsa -> affected package ranges

        ret = []
        current_pkg = None
        idx = 1

        for i, pkg in enumerate(self.get_pkgs()):
            ret += [""]
            vulnerable_ranges = self.get_vulnerable_for_pkg(pkg)
            unaffected_ranges = self.get_unaffected_for_pkg(pkg)
            vuln = vulnerable_ranges.pop()
            unaff = unaffected_ranges.pop()
            ret[i] += "  {}  {}".format(idx, pkg).ljust(32, " ") + "{} {}".format(
                vuln.range_types_rev[vuln.pkg_range], vuln.version
            )
            ret[i] += "{} {} ".format(
                unaff.range_types_rev[unaff.pkg_range], unaff.version
            ).rjust(70 - len(ret[i]))

        return "\n".join(ret)

    def generate_xml(self):
        return render_template("glsa.xml", glsa=self)

    def generate_mail_text(self):
        return render_template("glsa.mail", glsa=self)

    def generate_mail(
        self,
        date=None,
        smtpuser=None,
        replyto=None,
        smtpto=None,
        gpg_home=None,
        gpg_pass=None,
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

        if smtpuser:
            message = message.from_(smtpuser)
        if smtpto:
            message = message.to(smtpto)
        if date:
            message = message.date(date)
        if gpg_home and gpg_pass:
            # gnugp is not a typo, envelope's argument name is just
            # mispelled.
            message = message.gpg(gnugp_home=gpg_home).signature(passphrase=gpg_pass)
        return message

    def release_email(self) -> bool:
        server = (
            config["glsamaker"]["smtpserver"]
            if "smtpserver" in config["glsamaker"]
            else None
        )
        user = (
            config["glsamaker"]["smtpuser"]
            if "smtpuser" in config["glsamaker"]
            else None
        )
        smtppass = (
            config["glsamaker"]["smtppass"]
            if "smtppass" in config["glsamaker"]
            else None
        )
        smtpuser = config["glsamaker"]["smtpuser"]
        smtpto = config["glsamaker"]["smtpto"]
        replyto = config["glsamaker"]["replyto"]
        gpg_home = config["glsamaker"]["gpg_home"]
        gpg_pass = config["glsamaker"]["gpg_pass"]
        mail = self.generate_mail(
            date=datetime.now().strftime("%a, %d %b %Y %X"),
            smtpuser=smtpuser,
            replyto=replyto,
            smtpto=smtpto,
            gpg_home=gpg_home,
            gpg_pass=gpg_pass,
        )

        if not any([server, user, smtppass]):
            ret = mail.smtp("localhost", 25).send()
        else:
            ret = mail.smtp(server, 587, user, smtppass, "starttls").send()

        return bool(ret)

    def release(self):
        glsarepo = GLSARepo(
            "/var/lib/glsamaker/glsa",
            config["glsamaker"]["gpg_pass"],
            config["glsamaker"]["gpg_home"],
            ssh_key=config["glsamaker"]["ssh_key"],
            signing_key=config["glsamaker"]["signing_key"],
        )
        glsarepo.commit(self)
        glsarepo.push()
        mail_success = self.release_email()
        if not mail_success:
            app.logger.info(f"Mail failure for GLSA {self.glsa_id}")
