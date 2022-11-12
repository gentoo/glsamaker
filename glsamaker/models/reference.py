from glsamaker.app import Model, db


class Reference(Model):
    __tablename__ = "reference"

    ref_text = db.Column(db.String(), primary_key=True)
    url = db.Column(db.String())

    def __init__(self, ref_text, url=None):
        self.ref_text = ref_text
        if url:
            self.url = url
        else:
            if ref_text.startswith("CVE"):
                self.url = f"https://nvd.nist.gov/vuln/detail/{self.ref_text}"
            elif ref_text.startswith("WSA"):
                self.url = f"https://webkitgtk.org/security/{self.ref_text}.html"
            elif ref_text.startswith("GStreamer"):
                self.url = "https://gstreamer.freedesktop.org/security/"
                ref = ref_text.replace("GStreamer-", "")
                self.url += f"{ref.lower()}.html"
            elif ref_text.startswith("YSA"):
                self.url = f"https://www.yubico.com/support/security-advisories/{self.ref_text}"

    # TODO: see bug.py's new TODO
    @classmethod
    def new(cls, ref, url=None):
        row = cls.query.filter_by(ref_text=ref).first()
        if row:
            return row
        return Reference(ref, url)

    def __lt__(self, other) -> bool:
        parts = self.ref_text.split("-")
        other_parts = other.ref_text.split("-")

        if len(parts) != len(other_parts):
            return False

        for part, other_part in zip(parts, other_parts):
            if part != other_part:
                try:
                    return int(part) < int(other_part)
                except ValueError:
                    return False
        return False
