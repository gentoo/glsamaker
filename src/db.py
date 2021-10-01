import bcrypt
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()


class UserModel(db.Model):
    __tablename__ = 'users'

    uid = db.Column(db.String(), primary_key=True)
    password = db.Column(db.String())

    def __init__(self, uid, password):
        self.uid = uid
        self.password = password


class Database:
    def __init__(self, app):
        self.app = app
        db.init_app(app)

    def create_user(self, uid, password):
        hashed = bcrypt.hashpw(password, bcrypt.gensalt())
        with self.app.app_context():
            db.session.add(UserModel(uid=uid, password=hashed))
            db.session.commit()
