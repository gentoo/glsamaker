from flask import current_app as app
from flask_login import UserMixin

from glsamaker.extensions import base, db


class User(UserMixin, base):
    __tablename__ = "users"

    id = db.Column(db.Integer, primary_key=True)
    nick = db.Column(db.String())
    password = db.Column(db.String())

    def __init__(self, nick, password):
        self.nick = nick
        self.password = password


def uid_to_nick(uid):
    user = db.session.query(User).filter(User.id == uid).first()
    if user:
        return user.nick
    return None


def nick_to_uid(nick):
    user = db.session.query(User).filter(User.nick == nick).first()
    if user:
        return user.id
    return None


def create_user(nick, password=None):
    app.logger.info("Creating user {}".format(nick))
    db.session.merge(User(nick, password))
