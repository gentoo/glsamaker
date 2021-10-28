from app import db


class Reference(db.Model):
    __tablename__ = 'reference'

    ref_text = db.Column(db.String(), primary_key=True)
    url = db.Column(db.String())

    def __init__(self, ref_text, url):
        self.ref_text = ref_text
        self.url = url
