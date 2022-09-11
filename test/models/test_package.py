import pytest

from glsamaker.models.package import Affected


class TestAffected:
    @pytest.mark.parametrize(
        "a,b",
        [
            ("dev-java/oracle-jre-bin", "dev-java/oracle-jre-bin"),
            ("<dev-java/openjdk-17.0.2_p8:17", "<dev-java/openjdk-17.0.2_p8:17"),
        ],
    )
    def test_versioned_atom(self, a, b):
        atom = Affected(a, None, None, "*", None, "vulnerable").versioned_atom()
        assert atom == b
