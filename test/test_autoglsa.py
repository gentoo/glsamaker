from unittest.mock import Mock

import pytest
from pkgcore.ebuild import atom as atom_mod
from util import database

from glsamaker.app import app
from glsamaker.autoglsa import generate_resolution, get_max_versions, glsa_impact
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
    ],
)
def test_get_max_versions(a, expected):
    bugs = [Mock() for x in range(len(a))]
    for i in range(len(a)):
        bugs[i].summary = a[i]
    # Don't care about the ordering of the return here, so sort just
    # to ensure similarity
    assert sorted(get_max_versions(bugs)) == sorted(expected)


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


def test_autogenerate_glsa(database):
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
        == """
All Mozilla Firefox users should upgrade to the latest version:

# emerge --sync
# emerge --ask --oneshot --verbose ">=www-client/firefox-104.0:rapid"
"""
    )
