import pytest
from unittest.mock import Mock

from pkgcore.ebuild import atom as atom_mod

from glsamaker.autoglsa import glsa_impact, get_max_versions


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
    ],
)
def test_get_max_versions(a, expected):
    bugs = [Mock() for x in range(len(a))]
    for i in range(len(a)):
        bugs[i].summary = a[i]
    assert get_max_versions(bugs) == expected


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
