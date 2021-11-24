from app import db


class Reference(db.Model):
    __tablename__ = 'reference'

    ref_text = db.Column(db.String(), primary_key=True)
    url = db.Column(db.String())

    def __init__(self, ref_text, url=None):
        self.ref_text = ref_text
        if url:
            self.url = url
        else:
            if ref_text.startswith('CVE'):
                self.url = 'https://nvd.nist.gov/vuln/detail/' + self.ref_text

    # TODO: see bug.py's new TODO
    @classmethod
    def new(cls, ref, url=None):
        row = cls.query.filter_by(ref_text=ref).first()
        if row:
            return row
        return Reference(ref, url)
