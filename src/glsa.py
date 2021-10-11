from flask_sqlalchemy import SQLAlchemy

from db import User, db


class GLSA(db.Model):
    __tablename__ = 'glsas'

    id = db.Column(db.String(), primary_key=True)
    title = db.Column(db.String())
    synopsis = db.Column(db.String())
    product_type = db.Column(db.Enum('ebuild', 'infrastructure',
                                     name='product_types'))
    product = db.Column(db.String())
    announced = db.Column(db.String())
    revision_count = db.Column(db.Integer())
    revised_date = db.Column(db.Date())
    # TODO: bugs
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
    # TODO: affected
    background = db.Column(db.String())
    description = db.Column(db.String())
    impact_type = db.Column(db.Enum('minimal', 'low', 'medium',
                                    'normal', 'high',
                                    name='impact_types'))
    impact = db.Column(db.String())
    workaround = db.Column(db.String())
    resolution = db.Column(db.String())
    requester = db.Column(db.Integer, db.ForeignKey(User.id))
    requested_time = db.Column(db.DateTime())
    submitted_time = db.Column(db.DateTime())
