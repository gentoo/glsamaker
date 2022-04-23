from glsamaker.app import app
from glsamaker.models.glsa import GLSA
from glsamaker.glsarepo import GLSARepo
from util import database, gitrepo, gpghome


def test_commit(gitrepo, gpghome, database):
    repo = GLSARepo(gitrepo, "secret", gpghome, "")
    glsa = GLSA()
    with app.app_context():
        glsa.glsa_id = 1
        repo.commit(glsa)
    assert "Add glsa-1.xml" in repo.repo.head.commit.summary
    assert (
        "Signed-off-by: GLSAMaker <glsamaker@gentoo.org>"
        in repo.repo.head.commit.message
    )
    # TODO: Need to check the file was actually created, and verify
    # the commit. Gitpython doesn't support commit verification, and
    # doesn't seem to have a way to query diff information for the
    # first commit of a repo.
