from unittest.mock import MagicMock

from glsamaker.views import parse_atoms


def test_parse_atoms_unaffected():
    def getlist_returns(arg):
        if arg == "unaffected[]":
            return [
                ">=www-client/firefox-bin-91.12.0:esr",
                ">=www-client/firefox-91.12.0:esr",
                ">=www-client/firefox-bin-103.0:rapid",
                ">=www-client/firefox-103.0:rapid",
            ]
        elif arg == "unaffected_arch[]":
            return ["*", "*", "*", "*"]

    request = MagicMock()
    request.form = MagicMock()
    request.form.getlist = MagicMock(side_effect=getlist_returns)

    parse_atoms(request, "unaffected")


def test_parse_atoms_vulnerable():
    def getlist_returns(arg):
        if arg == "vulnerable[]":
            return [
                "dev-java/oracle-jre-bin",
                "dev-java/oracle-jdk-bin",
            ]
        elif arg == "vulnerable_arch[]":
            return ["*", "*", "*", "*"]

    request = MagicMock()
    request.form = MagicMock()
    request.form.getlist = MagicMock(side_effect=getlist_returns)

    parse_atoms(request, "vulnerable")
