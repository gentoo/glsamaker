from glsamaker.views import parse_atoms

# parse_atoms breaks on atom of >=www-client/firefox-bin-91.12.0:esr at
# pkg_range = Affected.range_types[pkg.replace(package.cpvstr, "")]

# just use pkg.op instead

from unittest.mock import MagicMock


def test_parse_atoms():
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
