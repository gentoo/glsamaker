from glsamaker.extensions import base, db


class Bug(base):
    __tablename__ = "bug"

    bug_id = db.Column(db.String(), primary_key=True)

    def __init__(self, bug):
        self.bug_id = bug
