from flask_login import UserMixin

from glsamaker.app import app, db


class User(UserMixin, db.Model):
    __tablename__ = "users"

    id = db.Column(db.Integer, primary_key=True)
    nick = db.Column(db.String())
    password = db.Column(db.String())

    def __init__(self, nick, password):
        self.nick = nick
        self.password = password


def uid_to_nick(uid):
    user = User.query.filter(User.id == uid).first()
    if user:
        return user.nick
    return None


def nick_to_uid(nick):
    user = User.query.filter(User.nick == nick).first()
    if user:
        return user.id
    return None


def create_user(nick, password=None):
    app.logger.info("Creating user {}".format(nick))
    db.session.merge(User(nick, password))
