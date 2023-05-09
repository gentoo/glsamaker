import os
from configparser import ConfigParser

from bugzilla import Bugzilla
from flask import Flask

from glsamaker.extensions import login_manager
from glsamaker.models.user import uid_to_nick


def create_app(dbpath: str):
    app = Flask(__name__)
    app.config["SECRET_KEY"] = os.urandom(32)
    app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
    app.config["SQLALCHEMY_DATABASE_URI"] = dbpath

    # Hack to allow uid_to_nick to be accessible in jinja templates so we
    # can use it in places like archive.html
    app.jinja_env.globals.update(uid_to_nick=uid_to_nick)

    app.jinja_env.lstrip_blocks = True
    app.jinja_env.trim_blocks = True

    # "lazy" import within the function to avoid a circular import
    from glsamaker.views import blueprint

    login_manager.init_app(app)
    app.register_blueprint(blueprint)

    return app


config = ConfigParser()
config.read("/etc/glsamaker/glsamaker.conf")

bgo = Bugzilla("https://bugs.gentoo.org")
