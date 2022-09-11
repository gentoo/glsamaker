from glsamaker.models.package import Affected


import pytest.mark.parametrize as parametrize


class TestAffected:
    @parametrize(
        "a,b",
        [
            ("dev-java/oracle-jre-bin", "dev-java/oracle-jre-bin"),
            ("<dev-java/openjdk-17.0.2_p8:17", "dev-java/openjdk-17.0.2_p8:17"),
        ],
    )
    def test_versioned_atom(self, a, b):
        assert Affected(a, None, None, "*", None, "vulnerable") == b
