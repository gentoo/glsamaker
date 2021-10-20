from flask_sqlalchemy import SQLAlchemy
from flask_login import UserMixin

from app import db


class User(UserMixin, db.Model):
    __tablename__ = 'users'

    id = db.Column(db.Integer, primary_key=True)
    nick = db.Column(db.String())
    password = db.Column(db.String())

    def __init__(self, nick, password):
        self.nick = nick
        self.password = password


def nick_to_uid(nick):
    user = User.query.filter(User.nick == nick).first()
    if user:
        return user.id
    return None


def create_user(nick, password=None):
    db.session.merge(User(nick, password))
