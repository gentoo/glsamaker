from glsamaker.models.reference import Reference


class TestReference:
    def test_reference_sort(self):
        a = Reference("CVE-2022-24713")
        b = Reference("CVE-2022-2505")

        assert b < a

    def test_reference_error(self):
        a = Reference("differing-parts")
        b = Reference("differing")

        try:
            a > b
        except Exception:
            raise
