from glsamaker.app import app
from glsamaker.models.glsa import GLSA
from glsamaker.glsarepo import GLSARepo
from util import GPG_TEST_PASSPHRASE, database, gitrepo, gpghome

import gnupg


def validate_commit(repo):
    assert "Add glsa-1.xml" in repo.repo.head.commit.summary
    assert (
        "Signed-off-by: GLSAMaker <glsamaker@gentoo.org>"
        in repo.repo.head.commit.message
    )
    # TODO: Need to check the file was actually created, and verify
    # the commit. Gitpython doesn't support commit verification, and
    # doesn't seem to have a way to query diff information for the
    # first commit of a repo.


def test_commit(gitrepo, gpghome, database):
    repo = GLSARepo(gitrepo, GPG_TEST_PASSPHRASE, gpghome)
    glsa = GLSA()
    with app.app_context():
        glsa.glsa_id = 1
        repo.commit(glsa)
    validate_commit(repo)


def test_commit_with_subkey(gitrepo, gpghome, database):
    gpg = gnupg.GPG(gnupghome=gpghome)
    subkey_fprint = list(gpg.list_keys()[0]["subkey_info"].keys())[0]
    repo = GLSARepo(gitrepo, GPG_TEST_PASSPHRASE, gpghome, signing_key=subkey_fprint)

    glsa = GLSA()
    with app.app_context():
        glsa.glsa_id = 1
        repo.commit(glsa)
    validate_commit(repo)
