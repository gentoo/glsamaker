import os
import sys
from configparser import ConfigParser

from bugzilla import Bugzilla
from flask import Flask
from flask_sqlalchemy import DefaultMeta, SQLAlchemy

app = Flask(__name__)
app.config["SECRET_KEY"] = os.urandom(32)
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

app.jinja_env.lstrip_blocks = True
app.jinja_env.trim_blocks = True

config = ConfigParser()
config.read("/etc/glsamaker/glsamaker.conf")

if "pytest" in sys.modules:
    # This is a hacky way to specify the default so that the default
    # is explicitly set to avoid a warning at test-time.
    app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite://"
else:
    app.config["SQLALCHEMY_DATABASE_URI"] = "postgresql://root:root@db/postgres"

db = SQLAlchemy(app)

Model: DefaultMeta = db.Model

bgo = Bugzilla("https://bugs.gentoo.org")
