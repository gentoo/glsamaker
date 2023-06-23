import os
import tempfile
from typing import Generator

import git
import gnupg
import pytest
from util import GPG_TEST_PASSPHRASE, SMTPUSER

from glsamaker.app import create_app
from glsamaker.extensions import base
from glsamaker.extensions import db as _db
from glsamaker.models.user import create_user


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


@pytest.fixture(autouse=True)
def app():
    _app = create_app("sqlite://")

    _app.jinja_loader.searchpath.append("glsamaker/templates")
    _app.config["WTF_CSRF_ENABLED"] = False
    with _app.app_context():
        yield _app


@pytest.fixture
def client(app):
    return app.test_client()


class AuthActions:
    def __init__(self, client):
        self._client = client

    def login(self, username="test", password="test"):
        return self._client.post(
            "/login", data={"username": username, "password": password}
        )


@pytest.fixture
def auth(client):
    # hash is "test"
    create_user("test", "$2b$12$JncrKachQFlDaNUksCg54eDzmkdu1VqQLpEYWVDMg5f/0KLHFn/XK")
    with AuthActions(client).login():
        yield client


@pytest.fixture(autouse=True)
def db(app):
    _db.init_app(app)
    with app.app_context():
        base.metadata.create_all(_db.engine)
    yield _db
