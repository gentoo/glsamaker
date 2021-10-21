from app import db


class Bug(db.Model):
    __tablename__ = 'bug'

    bug_id = db.Column(db.String(), primary_key=True)

    def __init__(self, bug):
        self.bug_id = bug
