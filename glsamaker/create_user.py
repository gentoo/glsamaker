#!/usr/bin/env python

import sys

import bcrypt
from sqlalchemy import create_engine

if __name__ == "__main__":
    if len(sys.argv) >= 2:
        db = create_engine("postgresql://root:root@db/postgres")
        try:
            bcrypt.checkpw(b"", sys.argv[2].encode("utf-8"))
        except ValueError:
            print("Invalid hash")
            raise
        ret = db.execute(
            "SELECT * FROM users WHERE nick='{}'".format(sys.argv[1])
        ).first()
        if ret:
            print("User already exists, updating password")
            if ret.password:
                print("Old hash: '{}'".format(ret.password))
            db.execute(
                "UPDATE users SET password='{}' WHERE nick='{}'".format(
                    sys.argv[2], sys.argv[1]
                )
            )
        else:
            print("Inserting new user '{}'".format(sys.argv[1]))
            db.execute(
                "INSERT INTO users (nick, password) VALUES ('{}', '{}')".format(
                    sys.argv[1], sys.argv[2]
                )
            )
    else:
        print("Usage: {} nick hash".format(sys.argv[0]))
