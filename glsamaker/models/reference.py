from typing import TypeGuard

from glsamaker.extensions import base, db


class InvalidReferenceFormatException(Exception):
    pass


class Reference(base):
    __tablename__ = "reference"

    ref_text = db.Column(db.String(), primary_key=True)
    url = db.Column(db.String())

    PREFIXES = [
        "CVE",
        "GHSA",
        "GLIBC-SA",
        "GStreamer",
        "MFSA",
        "TALOS",
        "TROVE",
        "VMSA",
        "WNPA-SEC",
        "WSA",
        "XSA",
        "YSA",
        "ZDI-CAN",
    ]

    def __init__(self, ref_text, url=None):
        # note that we can't actually raise exception on a validation
        # failure here yet because there are lots of old references
        # that wouldn't pass the validation, and this would block the
        # ingestion of old GLSAs
        # if not self.valid_reference(ref_text):
        #     raise InvalidReferenceFormatException

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
            elif ref_text.startswith("XSA"):
                ref_text_components = ref_text.split("-")
                if len(ref_text_components) > 1:
                    xsa_id = ref_text_components[1]
                    self.url = f"https://xenbits.xen.org/xsa/advisory-{xsa_id}.html"

    # TODO: see bug.py's new TODO
    @classmethod
    def new(cls, ref, url=None):
        row = db.session.query(cls).filter_by(ref_text=ref).first()
        if row:
            return row
        return Reference(ref, url)

    @classmethod
    def valid_reference(cls, ref_text: str) -> bool:
        # not using a lambda here and returning a type of
        # TypeGuard[object] seemingly for:
        # https://github.com/python/mypy/issues/12682
        def _ref_startswith_prefix(prefix: str) -> TypeGuard[object]:
            return ref_text.startswith(prefix)

        if not any(filter(_ref_startswith_prefix, cls.PREFIXES)):
            return False
        return True

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
