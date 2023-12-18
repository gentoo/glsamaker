import uuid
from unittest.mock import MagicMock

import pytest

from glsamaker.models.glsa import GLSA
from glsamaker.views import atom_to_affected, parse_atoms


def test_atom_to_affected():
    glsa = GLSA()
    glsa.affected = [
        atom_to_affected("dev-libs/libebml", "arm,ppc,sparc,x86", "unaffected")
    ]
    assert glsa.get_affected_arch("dev-libs/libebml") == "arm ppc sparc x86"


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


# TODO: maybe create an authoritative list of endpoints in views.py
# for use elsewhere
@pytest.mark.parametrize("endpoint", ["drafts", "edit_glsa", "newbugs", "archive"])
def test_unauthenticated(app, client, endpoint):
    # Unauthenticated requests to any ednpoint get redirected to login
    # page
    response = client.get(endpoint)

    assert response.status_code == 302
    assert response.location == "/login"


def test_authenticated(app, auth):
    response = auth.get("/drafts")
    assert response.status_code == 200


def test_newbugs(app, auth):
    response = auth.post(
        "/newbugs",
        data={"bugs": "828936"},
        follow_redirects=True,
    )

    assert response.status_code == 200


def test_edit_glsa(app, auth, db):
    glsa = GLSA()
    glsa.draft = True
    glsa.glsa_id = str(uuid.uuid4())
    db.session.merge(glsa)

    response = auth.get(f"/edit_glsa/{db.session.query(GLSA).first().glsa_id}")

    assert response.status_code == 200

    glsa_data = {
        # see views.GLSAForm for what's required here
        "title": "glsa title",
        "synopsis": "glsa synopsis",
        "product_type": "ebuild",
        "bugs": "123456,654321",
        "access": "remote",
        "background": "glsa background",
        "description": "glsa description",
        "impact": "glsa impact",
        "impact_type": "normal",
        "workaround": "glsa workaround",
        "resolution": "glsa resolution",
        "references": "glsa references",
        "submit": "Submit",
    }

    # a trivial submit test
    response = auth.post(
        f"/edit_glsa/{db.session.query(GLSA).first().glsa_id}",
        follow_redirects=True,
        data=glsa_data,
    )

    assert response.status_code == 200

    # TODO: test for idempotence too
    response = auth.post(
        f"/edit_glsa/{db.session.query(GLSA).first().glsa_id}",
        follow_redirects=True,
        data=glsa_data,
    )

    assert response.status_code == 200
