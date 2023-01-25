import os
from configparser import ConfigParser

from bugzilla import Bugzilla
from flask import Flask
from flask_sqlalchemy import DefaultMeta, SQLAlchemy

app = Flask(__name__)
app.config["SECRET_KEY"] = os.urandom(32)
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
app.config["SQLALCHEMY_DATABASE_URI"] = "postgresql://root:root@db/postgres"

app.jinja_env.lstrip_blocks = True
app.jinja_env.trim_blocks = True

config = ConfigParser()
config.read("/etc/glsamaker/glsamaker.conf")

db = SQLAlchemy(app)

Model: DefaultMeta = db.Model

bgo = Bugzilla("https://bugs.gentoo.org")
