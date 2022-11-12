from glsamaker.app import Model, db


class Bug(Model):
    __tablename__ = "bug"

    bug_id = db.Column(db.String(), primary_key=True)

    def __init__(self, bug):
        self.bug_id = bug

    # TODO: maybe this would be more comfortable by hacking about with
    # __new__ so that a class method doesn't have to be called?
    @classmethod
    def new(cls, bug):
        row = Bug.query.filter_by(bug_id=bug).first()
        if row:
            return row
        return Bug(bug)
