import difflib
import os
import tempfile
from typing import Generator

import git
import gnupg
import pytest
from util import GPG_TEST_PASSPHRASE, SMTPUSER

from glsamaker.app import app, db


@pytest.fixture
def gpghome() -> Generator[str, None, None]:
    with tempfile.TemporaryDirectory() as d:
        # Start a gpg-agent with the args we want, else it will get
        # started at gen_key with args of its choosing.
        # It will exit once out of the with block, because gpg-agent
        # exits once its homedir disappears.
        os.system(f"gpg-agent --daemon --allow-preset-passphrase --homedir={d}")
        gpg = gnupg.GPG(gnupghome=d)
        gpg.encoding = "utf-8"
        key = gpg.gen_key(
            gpg.gen_key_input(
                key_type="RSA",
                key_length=2048,
                name_email=SMTPUSER,
                passphrase=GPG_TEST_PASSPHRASE,
            )
        )
        gpg.add_subkey(
            master_key=key.fingerprint,
            master_passphrase=GPG_TEST_PASSPHRASE,
            usage="sign",
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
