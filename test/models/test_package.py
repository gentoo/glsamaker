import pytest
from pkgcore.ebuild import atom as atom_mod

from glsamaker.models.package import Affected


class TestAffected:
    @pytest.mark.parametrize(
        "a,b",
        [
            ("dev-java/oracle-jre-bin", "dev-java/oracle-jre-bin"),
            ("<dev-java/openjdk-17.0.2_p8:17", "<dev-java/openjdk-17.0.2_p8:17"),
            (
                "<dev-java/oracle-jre-bin-1.8.0.202",
                "<dev-java/oracle-jre-bin-1.8.0.202",
            ),
            ("<sys-boot/grub-2.06-r3", "<sys-boot/grub-2.06-r3"),
        ],
    )
    def test_versioned_atom(self, a, b):
        a = atom_mod.atom(a)
        atom = Affected(
            str(a.unversioned_atom),
            a.fullver,
            # 'if' to properly handle unversioned atoms
            Affected.range_types[a.op] if a.op else None,
            "*",  # we're testing versioning, so use all arches
            a.slot,
            "vulnerable",
        ).versioned_atom()
        assert atom == b
