import traceback
from datetime import datetime

from envelope import Envelope
from flask import render_template

from glsamaker.app import app, config, db
from glsamaker.glsarepo import GLSARepo
from glsamaker.models.reference import Reference
from glsamaker.models.user import User

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
        return sorted(references)

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
        return sorted(list(set([pkg.pkg for pkg in self.affected])))

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
        return list(filter(lambda x: x.pkg == pn, self.affected))

    def get_unaffected(self):
        return list(filter(lambda x: x.range_type == "unaffected", self.affected))

    def get_vulnerable(self):
        return list(filter(lambda x: x.range_type == "vulnerable", self.affected))

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

        # Get rid of trailing empty list member
        if not ret[-1]:
            ret.pop()
        return ret

    @property
    def resolution_text(self):
        lines = self.resolution.splitlines()
        ret = []

        for line in lines:
            line = line.strip()
            if line.startswith("#"):
                ret += ["  " + line]
            else:
                ret += [line]
        return "\n".join(ret)

    def _generate_mail_table(self) -> str:
        # TODO: Maybe try to do this in jinja. It worked for ruby in
        # glsamakerv2..
        # Probably needs to reorganize this in the db properly, so
        # that we can access glsa -> package -> affected ranges rather
        # than glsa -> affected package ranges

        ret = []
        line_idx = 0
        pkg_idx = 0

        # For each unique package...
        for pkg in sorted(self.get_pkgs()):
            pkg_idx += 1
            ret += ["  {}  {}".format(pkg_idx, pkg)]
            packages = list(filter(lambda x: x.pkg == pkg, self.affected))
            vulnerable_pkgs = list(
                filter(lambda x: x.range_type == "vulnerable", packages)
            )
            unaffected_pkgs = list(
                filter(lambda x: x.range_type == "unaffected", packages)
            )

            # Find each of this package's slots...
            slots = sorted(list({x.slot for x in self.affected if x.slot}))
            if slots:
                # If there are slots to deal with, find the
                # vulnerable/unaffected range indicators for each slot
                # and output them
                for slot in slots:
                    vulnerable = list(filter(lambda x: x.slot == slot, vulnerable_pkgs))
                    unaffected = list(filter(lambda x: x.slot == slot, unaffected_pkgs))

                    for vuln, unaff in zip(vulnerable, unaffected):
                        chunk = "{} {}:{}".format(
                            vuln.range_types_rev[vuln.pkg_range],
                            vuln.version,
                            vuln.slot,
                        )

                        ret[line_idx] += chunk.rjust(
                            32 + len(chunk) - len(ret[line_idx])
                        )

                        chunk = "{} {}:{}".format(
                            unaff.range_types_rev[unaff.pkg_range],
                            unaff.version,
                            unaff.slot,
                        )

                        ret[line_idx] += chunk.rjust(69 - len(ret[line_idx]))

                        if pkg in ret[line_idx]:
                            # If we don't conditionally add the new
                            # list element (which gets converted into
                            # a newline on return), we get line_idx
                            # being out of sync with the length of ret
                            ret += [""]

                        line_idx += 1
            else:
                # If there aren't slots to deal with, just output the
                # ranges without dealing with slots
                vulnerable = list(
                    filter(
                        lambda x: x.range_type == "vulnerable" and x.pkg == pkg,
                        self.affected,
                    )
                )
                unaffected = list(
                    filter(
                        lambda x: x.range_type == "unaffected" and x.pkg == pkg,
                        self.affected,
                    )
                )

                vuln = vulnerable.pop()

                if len(unaffected) > 0:
                    unaff = unaffected.pop()
                else:
                    unaff = []

                # Add to the line in chunks for readability
                chunk = "{} {}".format(
                    vuln.range_types_rev[vuln.pkg_range], vuln.version
                )

                offset = 32

                if len(ret[line_idx]) >= offset:
                    # If the line is so long that it leaves no spacing
                    # between it and the next chunk, break the line
                    # and add some extra spacing
                    offset += 2

                ret[line_idx] += chunk.rjust(offset + len(chunk) - len(ret[line_idx]))

                offset = 69

                if unaff:
                    chunk = "{} {}".format(
                        unaff.range_types_rev[unaff.pkg_range], unaff.version
                    )
                else:
                    chunk = "Vulnerable!"
                ret[line_idx] += chunk.rjust(offset - len(ret[line_idx]))

                line_idx += 1

        return "\n".join(ret).rstrip()

    def generate_mail_table(self) -> str:
        try:
            return self._generate_mail_table()
        except:
            bt = traceback.format_exc()
            app.logger.info(bt)
            return bt

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
