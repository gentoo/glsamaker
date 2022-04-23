import difflib
import os
import pytest
import tempfile

from glsamaker.app import db
from glsamaker.glsarepo import GLSARepo

import git
import gnupg


GPG_TEST_PASSPHRASE = "secret"


def assert_diff(src: list[str], target: list[str]):
    for line in difflib.unified_diff(src, target, fromfile="a", tofile="b"):
        print(line)
    return src == target


@pytest.fixture
def gpghome() -> str:
    with tempfile.TemporaryDirectory() as d:
        # Start a gpg-agent with the args we want, else it will get
        # started at gen_key with args of its choosing
        os.system(f"gpg-agent --daemon --allow-preset-passphrase --homedir={d}")
        gpg = gnupg.GPG(gnupghome=d)
        gpg.encoding = "utf-8"
        gpg.gen_key(
            gpg.gen_key_input(
                key_type="RSA", key_length=2048, passphrase=GPG_TEST_PASSPHRASE
            )
        )
        yield d


@pytest.fixture
def gitrepo():
    with tempfile.TemporaryDirectory() as d:
        directory = d
        repo = git.Repo.init(d)
        repo.create_remote("origin", "ssh://git@git.gentoo.org/data/glsa.git")
        del repo
        yield directory


@pytest.fixture
def database():
    db.create_all()
