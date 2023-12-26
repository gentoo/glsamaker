import pytest

from glsamaker.models.reference import Reference


class TestReference:
    def test_reference_sort(self):
        a = Reference("CVE-2022-24713")
        b = Reference("CVE-2022-2505")

        assert b < a
        assert not b > a

    def test_reference_sort_error(self):
        a = Reference("differing-parts")
        b = Reference("differing")

        try:
            a > b
        except Exception:
            raise

    @pytest.mark.parametrize(
        "identifier,url",
        [
            ("CVE-2022-1234", "https://nvd.nist.gov/vuln/detail/CVE-2022-1234"),
            ("WSA-2022-0001", "https://webkitgtk.org/security/WSA-2022-0001.html"),
            (
                "GStreamer-SA-2021-0001",
                "https://gstreamer.freedesktop.org/security/sa-2021-0001.html",
            ),
            (
                "YSA-2021-03",
                "https://www.yubico.com/support/security-advisories/YSA-2021-03",
            ),
        ],
    )
    def test_reference_url(self, identifier, url):
        assert Reference(identifier).url == url

    def test_valid_reference(self):
        invalid_references = ["-fno-common", "VE-2023-0001", "2023-1234"]
        valid_references = ["CVE-2023-1234", "TALOS-2023-1234"]

        for reference in valid_references:
            assert Reference.valid_reference(reference)

        for reference in invalid_references:
            assert not Reference.valid_reference(reference)
