import gnupg
from git.exc import GitCommandError
from util import GPG_TEST_PASSPHRASE, database, gitrepo, gpghome

from glsamaker.app import app
from glsamaker.glsarepo import GLSARepo
from glsamaker.models.bug import Bug
from glsamaker.models.glsa import GLSA


def validate_commit(repo):
    assert (
        "[ GLSA 1 ] Foo Bar: Multiple vulnerabilities" in repo.repo.head.commit.summary
    )
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
        glsa.title = "Foo Bar: Multiple vulnerabilities"
        repo.commit(glsa)
    validate_commit(repo)


def test_commit_without_subkey(gitrepo, gpghome, database):
    gpg = gnupg.GPG(gnupghome=gpghome)
    repo = GLSARepo(gitrepo, GPG_TEST_PASSPHRASE, gpghome)

    glsa = GLSA()
    with app.app_context():
        glsa.glsa_id = 1
        glsa.title = "Foo Bar: Multiple vulnerabilities"
        repo.commit(glsa)
    validate_commit(repo)


def test_commit_with_subkey(gitrepo, gpghome, database):
    gpg = gnupg.GPG(gnupghome=gpghome)
    subkey_fprint = list(gpg.list_keys()[0]["subkey_info"].keys())[0]
    repo = GLSARepo(gitrepo, GPG_TEST_PASSPHRASE, gpghome, signing_key=subkey_fprint)

    glsa = GLSA()
    with app.app_context():
        glsa.glsa_id = 1
        glsa.title = "Foo Bar: Multiple vulnerabilities"
        repo.commit(glsa)
    validate_commit(repo)


def test_commit_failure(gitrepo, gpghome, database):
    repo = GLSARepo(gitrepo, GPG_TEST_PASSPHRASE, gpghome, signing_key="doesn't exist")

    glsa = GLSA()
    with app.app_context():
        glsa.glsa_id = 1
        glsa.title = "Foo Bar: Multiple vulnerabilities"
        try:
            repo.commit(glsa)
        except GitCommandError:
            assert len(repo.repo.untracked_files) == 0
            assert not repo.repo.is_dirty()
        else:
            # The git command should've failed since signing_key is
            # garbage
            assert False


def test_commit_bugs(gitrepo, gpghome, database):
    repo = GLSARepo(gitrepo, GPG_TEST_PASSPHRASE, gpghome)

    glsa = GLSA()
    with app.app_context():
        glsa.glsa_id = 1
        glsa.title = "Foo Bar: Multiple vulnerabilities"
        glsa.bugs = [Bug("654321"), Bug("123456")]
        repo.commit(glsa)

    expected = """[ GLSA 1 ] Foo Bar: Multiple vulnerabilities

Bug: https://bugs.gentoo.org/123456
Bug: https://bugs.gentoo.org/654321
Signed-off-by: GLSAMaker <glsamaker@gentoo.org>
"""

    assert expected == repo.repo.head.commit.message
