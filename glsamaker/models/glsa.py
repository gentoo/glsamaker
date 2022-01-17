from datetime import datetime

from sqlalchemy import select

from glsamaker.app import app, db
from glsamaker.models.bug import Bug
from glsamaker.models.reference import Reference
from glsamaker.models.user import User
from glsamaker.models.package import Package


glsa_to_bug = db.Table('glsa_to_bug',
                       db.Column('glsa_id', db.String(),
                                 db.ForeignKey('glsa.glsa_id',
                                               onupdate="cascade")),
                       db.Column('bug_id', db.String(),
                                 db.ForeignKey('bug.bug_id',
                                               onupdate="cascade")))

glsa_to_ref = db.Table('glsa_to_ref',
                       db.Column('glsa_id', db.String(),
                                 db.ForeignKey('glsa.glsa_id',
                                               onupdate="cascade")),
                       db.Column('ref_text', db.String(),
                                 db.ForeignKey('reference.ref_text',
                                               onupdate="cascade")))

glsa_to_affected = db.Table('glsa_to_affected',
                            db.Column('glsa_id', db.String(),
                                      db.ForeignKey('glsa.glsa_id',
                                                    onupdate="cascade")),
                            db.Column('affected_id', db.Integer(),
                                      db.ForeignKey('affected.affected_id',
                                                    onupdate="cascade")))


class GLSA(db.Model):
    __tablename__ = 'glsa'

    id = db.Column(db.Integer(), primary_key=True)
    glsa_id = db.Column(db.String(), unique=True)
    draft = db.Column(db.Boolean())
    title = db.Column(db.String())
    synopsis = db.Column(db.String())
    product_type = db.Column(db.Enum('ebuild', 'infrastructure',
                                     name='product_types'))
    product = db.Column(db.String())
    announced = db.Column(db.Date())
    revision_count = db.Column(db.Integer())
    revised_date = db.Column(db.Date())
    bugs = db.relationship("Bug", secondary=glsa_to_bug)
    # TODO: lots of variation here, we should cleanup eventually
    access = db.Column(db.Enum('unknown', 'local', 'remote',
                               'local, remote',
                               'remote, local',
                               'local and remote',
                               # glsa-200503-10
                               'remote and local',
                               # glsa-200311-0{1,2}
                               'local / remote',
                               # glsa-200403-01
                               'local and remote combination',
                               # glsa-201001-03, glsa-201011-01
                               'local remote',
                               # glsa-200408-18
                               'remote root',
                               # glsa-200401-04
                               'man-in-the-middle',
                               # glsa-200312-01
                               '',
                               name='access_types'))
    affected = db.relationship("Affected", secondary=glsa_to_affected)
    background = db.Column(db.String())
    description = db.Column(db.String())
    impact_type = db.Column(db.Enum('minimal', 'low', 'medium',
                                    'normal', 'high',
                                    name='impact_types'))
    impact = db.Column(db.String())
    workaround = db.Column(db.String())
    resolution = db.Column(db.String())
    resolution_code = db.Column(db.String())
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
        date = '{}{:02}'.format(now.year, now.month)
        query = db.session.query(cls).filter(cls.glsa_id.startswith(date)).all()
        n = 1
        if query:
            ids = [int(x.glsa_id.split('-')[1]) for x in query]
            n = max(ids) + 1
        return '{}-{:02}'.format(date, n)

    def get_bugs(self):
        return [bug.bug_id for bug in self.bugs]

    def get_references(self):
        return [ref.ref_text for ref in self.references]

    def get_pkgs(self):
        return set([pkg.pkg for pkg in self.affected])

    def get_affected_arch(self, pn):
        ret = set()
        for pkg in [pkg for pkg in self.affected if pkg.pkg == pn]:
            ret.add(pkg.arch)
        if len(ret) > 1:
            app.logger.error("Something has gone horribly wrong with GLSA {}!".format(self.id))
            app.logger.error("{} has multiple arches: {}".format(pkg, ret))
        return list(ret)[0]

    def get_affected_for_pkg(self, pn):
        return [pkg for pkg in self.affected if pkg.pkg == pn]

    def get_vulnerable_for_pkg(self, pn):
        return [pkg for pkg in self.affected if pkg.pkg == pn and pkg.range_type == 'vulnerable']

    def get_unaffected_for_pkg(self, pn):
        return [pkg for pkg in self.affected if pkg.pkg == pn and pkg.range_type == 'unaffected']

    def get_unaffected(self):
        return [pkg for pkg in self.affected if pkg.range_type == 'unaffected']

    def get_vulnerable(self):
        return [pkg for pkg in self.affected if pkg.range_type == 'vulnerable']

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
            ret += ['']
            vulnerable_ranges = self.get_vulnerable_for_pkg(pkg)
            unaffected_ranges = self.get_unaffected_for_pkg(pkg)
            vuln = vulnerable_ranges.pop()
            unaff = unaffected_ranges.pop()
            ret[i] += '  {}  {}'.format(idx, pkg).ljust(32, ' ') \
                + '{} {}'.format(vuln.range_types_rev[vuln.pkg_range], vuln.version)
            ret[i] += '{} {} '.format(unaff.range_types_rev[unaff.pkg_range], unaff.version).rjust(70 - len(ret[i]))

        return '\n'.join(ret)
