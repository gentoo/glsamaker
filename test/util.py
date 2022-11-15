import difflib
import os
import tempfile
from typing import Generator

import git
import gnupg
import pytest

from glsamaker.app import app, db

GPG_TEST_PASSPHRASE = "secret"
SMTPUSER = "glsamaker@gentoo.org"


def assert_diff(src: list[str], target: list[str]):
    for line in difflib.unified_diff(src, target, fromfile="a", tofile="b"):
        print(line)
    return src == target
