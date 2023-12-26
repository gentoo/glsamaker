#!/usr/bin/env python

import sys

import bcrypt
from flask_sqlalchemy import SQLAlchemy

from glsamaker.app import create_app
from glsamaker.extensions import db
from glsamaker.models.user import User


def add_user(db: SQLAlchemy, nick: str, pw_hash: str) -> None:
    users = db.session.query(User).filter_by(nick=nick).all()
    if len(users) > 0:
        print(f"User '{nick}' already exists, updating password")
        user = users[0]
        user.password = pw_hash
        db.session.merge(user)
    else:
        print(f"Inserting new user '{nick}'")
        db.session.merge(User(nick, pw_hash))
    db.session.commit()


if __name__ == "__main__":
    if not len(sys.argv) >= 2:
        print("Usage: {} nick hash".format(sys.argv[0]))
        sys.exit(1)

    nick = sys.argv[1]
    pw_hash = sys.argv[2]

    app = create_app("postgresql://root:root@db/postgres")

    try:
        bcrypt.checkpw(b"", pw_hash.encode("utf-8"))
    except ValueError:
        print("Invalid hash! Generate a hash with something like:")
        print(
            "$ python -c \"import bcrypt; import getpass; print(bcrypt.hashpw(getpass.getpass().encode('utf-8'), bcrypt.gensalt()).decode())\""
        )
        raise

    with app.app_context():
        db.init_app(app)
        add_user(db, nick, pw_hash)
