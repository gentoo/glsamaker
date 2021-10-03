#!/usr/bin/env python3

from flask import redirect

from db import Database, db
from website import app


if __name__ == "__main__":
    Database(app)
    app.run(host='0.0.0.0', port=8080)
