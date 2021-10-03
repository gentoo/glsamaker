#!/usr/bin/env python

import sys

from website import app
from db import Database


if __name__ == '__main__':
    if len(sys.argv) >= 2:
        db = Database(app)
        db.create_user(sys.argv[1], sys.argv[2])
    else:
        print("Usage: {} nick hash".format(sys.argv[0]))
