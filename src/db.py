from flask_sqlalchemy import SQLAlchemy
from flask_login import UserMixin

db = SQLAlchemy()


class User(UserMixin, db.Model):
    __tablename__ = 'users'

    id = db.Column(db.Integer, primary_key=True)
    nick = db.Column(db.String())
    password = db.Column(db.String())

    def __init__(self, nick, password):
        self.nick = nick
        self.password = password


class Database:
    def __init__(self, app):
        self.app = app
        db.init_app(app)
        with self.app.app_context():
            db.create_all()

    def add_model(self, model):
        with self.app.app_context():
            db.session.add(model)
            db.session.commit()

    def update_glsa(self, table, model):
        with self.app.app_context():
            db.session.merge(model)
            db.session.commit()

    def create_user(self, nick, password_hash):
        self.add_model(User(nick=nick, password=password_hash))
