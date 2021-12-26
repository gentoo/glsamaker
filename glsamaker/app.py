from configparser import ConfigParser
import os

from flask_sqlalchemy import SQLAlchemy
from flask import Flask

app = Flask(__name__)
app.config['SECRET_KEY'] = os.urandom(32)
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

config = ConfigParser()
config.read("/etc/glsamaker/glsamaker.conf")

if __name__ == '__main__':
    app.config['SQLALCHEMY_DATABASE_URI'] = "postgresql://root:root@db/postgres"
else:
    # This is a hacky way to specify the default so that the default
    # is explicitly set to avoid a warning at test-time.
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite://'

db = SQLAlchemy(app)
