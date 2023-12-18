from unittest.mock import Mock

import pytest
from pkgcore.ebuild import atom as atom_mod

from glsamaker.autoglsa import (
    NoAtomInSummary,
    autogenerate_glsa,
    generate_resolution,
    get_max_versions,
    glsa_impact,
)
from glsamaker.models.glsa import GLSA
from glsamaker.models.package import Affected


@pytest.mark.parametrize(
    "a,expected",
    [
        pytest.param(
            [
                "<www-client/firefox{-bin,}-{91.6.1,97.0.2}: code execution and sandbox escape (actively exploited)",
                "<www-client/firefox{-bin,}-{91.7.0,98.0}: multiple vulnerabilities",
            ],
            [
                atom_mod.atom("<www-client/firefox-bin-98.0"),
                atom_mod.atom("<www-client/firefox-98.0"),
            ],
        ),
        pytest.param(
            [
                "<www-servers/apache-2.4.52: multiple vulnerabilities",
                "=www-servers/apache-2.4.49: Multiple vulnerabilities",
            ],
            [atom_mod.atom("<www-servers/apache-2.4.52")],
        ),
        pytest.param(
            ["<dev-libs/nss-{3.68.4, 3.79}: Multiple vulnerabilities"],
            [atom_mod.atom("<dev-libs/nss-3.79")],
        ),
        pytest.param(
            [
                "<mail-client/thunderbird{-bin,}-91.12.0: multiple vulnerabilities",
                "<mail-client/thunderbird{-bin,}-91.9.1: multiple vulnerabilities",
            ],
            [
                atom_mod.atom("<mail-client/thunderbird-91.12.0"),
                atom_mod.atom("<mail-client/thunderbird-bin-91.12.0"),
            ],
        ),
        pytest.param(
            [
                # Somewhat contrived example (in that it's made up) to
                # produce the what should be the most logically
                # complex thing we have to parse
                "<www-client/{chromium, microsoft-edge}-103.0.5060.134 <www-client/google-chrome-103.0.5060.134: Multiple vulnerabilities",
            ],
            [
                atom_mod.atom("<www-client/chromium-103.0.5060.134"),
                atom_mod.atom("<www-client/microsoft-edge-103.0.5060.134"),
                atom_mod.atom("<www-client/google-chrome-103.0.5060.134"),
            ],
        ),
        pytest.param(
            [
                "<dev-java/openjdk{,-jre-bin,-bin}-{8.312_p07, 11.0.13_p8}: multiple vulnerabilities (CVE-2021-{2341,2369,2388,2432})"
            ],
            [
                atom_mod.atom("<dev-java/openjdk-11.0.13_p8"),
                atom_mod.atom("<dev-java/openjdk-jre-bin-11.0.13_p8"),
                atom_mod.atom("<dev-java/openjdk-bin-11.0.13_p8"),
            ],
        ),
        pytest.param(
            ["<sys-boot/grub-2.06-r3: creates config file world-readable"],
            [
                atom_mod.atom("<sys-boot/grub-2.06-r3"),
            ],
        ),
        pytest.param(
            [
                "<dev-lang/python-{2.7.18_p11,3.6.13_p5,3.7.10_p6,3.8.10_p2,3.9.5_p2,3.10.0_beta2} <dev-python/pypy-7.3.4_p1, <dev-python/pypy3-{7.3.4_p2,7.3.5_rc3_p1}"
            ],
            [
                # TODO: This isn't quite what we want for GLSA
                # targeting, but this covers another summary -> atom
                # edge case
                atom_mod.atom("<dev-lang/python-3.10.0_beta2"),
                atom_mod.atom("<dev-python/pypy-7.3.4_p1"),
                atom_mod.atom("<dev-python/pypy3-7.3.5_p1"),
            ],
            marks=pytest.mark.xfail,
        ),
    ],
)
def test_get_max_versions(a, expected):
    bugs = [Mock() for x in range(len(a))]
    for i in range(len(a)):
        bugs[i].summary = a[i]
    # Don't care about the ordering of the return here, so sort just
    # to ensure similarity
    versions, _ = get_max_versions(bugs)
    assert sorted(versions) == sorted(expected)


@pytest.mark.parametrize(
    "a,expected",
    [
        pytest.param("A0", "high"),
        pytest.param("B0", "high"),
        pytest.param("A1", "high"),
        pytest.param("C0", "high"),
        pytest.param("A2", "high"),
        pytest.param("B1", "high"),
        pytest.param("C1", "high"),
        pytest.param("A3", "normal"),
        pytest.param("B2", "normal"),
        pytest.param("C2", "normal"),
        pytest.param("A4", "low"),
        pytest.param("B3", "low"),
        pytest.param("B4", "low"),
        pytest.param("C3", "low"),
    ],
)
def test_glsa_impact(a, expected):
    mock = Mock()
    mock.whiteboard = a
    assert glsa_impact([mock]) == expected


def test_generate_resolution(app, db):
    glsa = GLSA()
    glsa.glsa_id = "1"

    with app.app_context():
        glsa.affected = [
            Affected(
                "www-client/firefox",
                "104.0",
                Affected.range_types[">="],
                "*",
                "rapid",
                "unaffected",
            )
        ]
        output = generate_resolution(glsa, "Mozilla Firefox")

    assert (
        output
        == """All Mozilla Firefox users should upgrade to the latest version:

# emerge --sync
# emerge --ask --oneshot --verbose ">=www-client/firefox-104.0:rapid"
""".strip()
    )


def test_autogenerate_glsa(app, db):
    bug = Mock()
    bug.id = 828936
    bug.whiteboard = "A0"
    bug.product = "Gentoo Security"
    bug.component = "Vulnerabilities"
    bug.assignee = "security@gentoo.org"
    bug.summary = (
        "<games-server/minecraft-server-1.18.1 remote code execution via bundled log4j"
    )

    glsa, errors = autogenerate_glsa([bug])

    assert len(errors) == 1

    e = errors[0]
    assert isinstance(e, NoAtomInSummary)
    assert e.bug_id == bug.id
