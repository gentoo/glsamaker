import os
import tempfile
from pathlib import Path

import gnupg
from util import GPG_TEST_PASSPHRASE, SMTPUSER, assert_diff

from glsamaker import main
from glsamaker.models.bug import Bug
from glsamaker.models.glsa import GLSA
from glsamaker.models.package import Affected
from glsamaker.models.reference import Reference

GLSA_FILE_DIR = Path(os.path.dirname(__file__)) / ".." / "files" / "glsa"
GLSAS = [
    GLSA_FILE_DIR / "glsa-202107-39",
    GLSA_FILE_DIR / "glsa-202107-48",
    GLSA_FILE_DIR / "glsa-202107-55",
    GLSA_FILE_DIR / "glsa-slotted-firefox",
]


def test_get_bugs(db):
    ids = ["1234", "4321", "1111", "2222"]
    glsa = GLSA()
    for x in ids:
        glsa.bugs.append(Bug.new(x))

    db.session.merge(glsa)

    assert sorted(ids) == glsa.get_bugs()


def test_resolution_xml():
    glsa = GLSA()
    glsa.resolution = '''All SDL 2 users should upgrade to the latest version:

  # emerge --sync
  # emerge --ask --oneshot --verbose "&gt;=media-libs/libsdl2-2.0.14-r1"'''

    expected = """<p>All SDL 2 users should upgrade to the latest version:</p>

<code>
  # emerge --sync
  # emerge --ask --oneshot --verbose "&gt;=media-libs/libsdl2-2.0.14-r1"
</code>"""

    assert assert_diff(expected.splitlines(), glsa.resolution_xml)

    glsa.resolution = '''All Chromium users should upgrade to the latest version:

  # emerge --sync
  # emerge --ask --oneshot --verbose "&gt;=www-client/chromium-91.0.4472.164"

All Google Chrome users should upgrade to the latest version:

  # emerge --sync
  # emerge --ask --oneshot --verbose "&gt;=www-client/google-chrome-91.0.4472.164"'''

    expected = """<p>All Chromium users should upgrade to the latest version:</p>

<code>
  # emerge --sync
  # emerge --ask --oneshot --verbose "&gt;=www-client/chromium-91.0.4472.164"
</code>

<p>All Google Chrome users should upgrade to the latest version:</p>

<code>
  # emerge --sync
  # emerge --ask --oneshot --verbose "&gt;=www-client/google-chrome-91.0.4472.164"
</code>"""

    assert assert_diff(expected.splitlines(), glsa.resolution_xml)

    glsa.resolution = '''All Mozilla Firefox ESR users should upgrade to the latest version:

  # emerge --sync
  # emerge --ask --oneshot --verbose "&gt;=www-client/firefox-78.11.0"

All Mozilla Firefox ESR binary users should upgrade to the latest version:

  # emerge --sync
  # emerge --ask --oneshot --verbose "&gt;=www-client/firefox-bin-78.11.0"

All Mozilla Firefox users should upgrade to the latest version:

  # emerge --sync
  # emerge --ask --oneshot --verbose "&gt;=www-client/firefox-89.0"

All Mozilla Firefox binary users should upgrade to the latest version:

  # emerge --sync
  # emerge --ask --oneshot --verbose "&gt;=www-client/firefox-bin-89.0"'''

    expected = """<p>All Mozilla Firefox ESR users should upgrade to the latest version:</p>

<code>
  # emerge --sync
  # emerge --ask --oneshot --verbose "&gt;=www-client/firefox-78.11.0"
</code>

<p>All Mozilla Firefox ESR binary users should upgrade to the latest version:</p>

<code>
  # emerge --sync
  # emerge --ask --oneshot --verbose "&gt;=www-client/firefox-bin-78.11.0"
</code>

<p>All Mozilla Firefox users should upgrade to the latest version:</p>

<code>
  # emerge --sync
  # emerge --ask --oneshot --verbose "&gt;=www-client/firefox-89.0"
</code>

<p>All Mozilla Firefox binary users should upgrade to the latest version:</p>

<code>
  # emerge --sync
  # emerge --ask --oneshot --verbose "&gt;=www-client/firefox-bin-89.0"
</code>"""
    assert assert_diff(expected.splitlines(), glsa.resolution_xml)


def test_get_references(db):
    # TODO: the db object should be the same throughout all tests
    # rather than being created somewhat arbitrarily here
    db.create_all()
    glsa = GLSA()
    glsa.glsa_id = "test glsa"
    cves = ["CVE-2021-4321", "CVE-2021-1234"]

    for text in cves:
        glsa.references.append(Reference.new(text))
    db.session.merge(glsa)

    assert glsa.get_reference_texts() == sorted(cves)


def striplines(lines):
    return [line.strip() for line in lines]


def file_contents(path):
    with open(path) as f:
        return f.readlines()


def test_regenerate_xml(db):
    # TODO: instead of diffing literal strings of XML, we should be
    # diffing actual xml contents.. somehow. Currently, we're often
    # testing for inconsequential whitespace differences
    for glsa_path in GLSAS:
        xml_path = "{}.xml".format(glsa_path)
        glsa = main.xml_to_glsa(xml_path)
        db.session.merge(glsa)
        glsa_contents = striplines(file_contents(xml_path))
        xml = striplines(glsa.generate_xml().splitlines())
        assert assert_diff(glsa_contents, xml)


def test_generate_mail_from_xml(db):
    for glsa_path in GLSAS:
        xml_path = "{}.xml".format(glsa_path)
        mail_path = "{}.mail".format(glsa_path)
        glsa = main.xml_to_glsa(xml_path)
        db.session.merge(glsa)
        mail_contents = [line.strip("\n") for line in file_contents(mail_path)]
        time = "Fri, 23 Jul 2021 22:10:35 -0500"
        generated_mail = (
            glsa.generate_mail(
                date=time, smtpuser=SMTPUSER, replyto="security@gentoo.org"
            )
            .as_message()
            .as_string()
            .splitlines()
        )
        try:
            assert assert_diff(mail_contents, generated_mail)
        except:
            print(glsa_path)
            raise


# https://gist.github.com/angelsenra/60397a72f29e58a7a4c27ed80c6c62d9
def test_generate_mail_signed(app, db, gpghome):
    gpg = gnupg.GPG(gnupghome=gpghome)
    subkey_fprint = list(gpg.list_keys()[0]["subkey_info"].keys())[0]
    with app.app_context():
        # Doesn't matter which GLSA we use here, we only need
        # something that will generate the mail properly as we're not
        # testing just how properly it's generated.
        glsa = main.xml_to_glsa(f"{GLSAS[0]}.xml")
        db.session.merge(glsa)
        generated_mail = glsa.generate_mail(
            smtpuser=SMTPUSER,
            replyto="security@gentoo.org",
            gpg_home=gpghome,
            gpg_pass=GPG_TEST_PASSPHRASE,
            signing_key=subkey_fprint,
        ).as_message()

    content, signature = generated_mail.get_payload()

    with tempfile.NamedTemporaryFile() as sig_tmpfile:
        sig_tmpfile.write(signature.get_payload().encode())
        sig_tmpfile.seek(0)
        assert gpg.verify_data(
            sig_filename=sig_tmpfile.name, data=content.as_string().encode()
        )


def test_generate_mail_table(db):
    # glsa-202305-15
    glsa = GLSA()
    glsa.affected = [
        Affected("sys-apps/systemd", "251.3", "lt", "*", "0", "vulnerable"),
        Affected("sys-apps/systemd", "251.3", "ge", "*", "0", "unaffected"),
        Affected("sys-apps/systemd-utils", "251.3", "lt", "*", "0", "vulnerable"),
        Affected("sys-apps/systemd-utils", "251.3", "ge", "*", "0", "unaffected"),
        Affected("sys-apps/systemd-tmpfiles", "251.3", "lt", "*", "0", "vulnerable"),
        Affected("sys-fs/udev", "251.3", "lt", "*", "0", "vulnerable"),
    ]
    db.session.merge(glsa)

    table = glsa.generate_mail_table()

    expected = """
Package                    Vulnerable    Unaffected
-------------------------  ------------  ------------
sys-apps/systemd           < 251.3       >= 251.3
sys-apps/systemd-tmpfiles  < 251.3       Vulnerable!
sys-apps/systemd-utils     < 251.3       >= 251.3
sys-fs/udev                < 251.3       Vulnerable!
""".strip()
    assert assert_diff(expected.splitlines(), table.splitlines())

    glsa = GLSA()
    # glsa-202305-02
    glsa.affected = [
        Affected("dev-lang/python", "3.8.15_p3", "lt", "*", "3.8", "vulnerable"),
        Affected("dev-lang/python", "3.8.15_p3", "ge", "*", "3.8", "unaffected"),
        Affected("dev-lang/python", "3.9.15_p3", "lt", "*", "3.9", "vulnerable"),
        Affected("dev-lang/python", "3.9.15_p3", "ge", "*", "3.9", "unaffected"),
        Affected("dev-lang/python", "3.10.8_p3", "lt", "*", "3.10", "vulnerable"),
        Affected("dev-lang/python", "3.10.8_p3", "ge", "*", "3.10", "unaffected"),
        Affected("dev-lang/python", "3.11.0_p2", "lt", "*", "3.11", "vulnerable"),
        Affected("dev-lang/python", "3.11.0_p2", "ge", "*", "3.11", "unaffected"),
        Affected(
            "dev-lang/python", "3.12.0_alpha1_p2", "lt", "*", "3.12", "vulnerable"
        ),
        Affected(
            "dev-lang/python", "3.12.0_alpha1_p2", "ge", "*", "3.12", "unaffected"
        ),
        Affected("dev-lang/pypy3", "7.3.9_p9", "lt", "*", "0", "vulnerable"),
        Affected("dev-lang/pypy3", "7.3.9_p9", "ge", "*", "0", "unaffected"),
    ]
    db.session.merge(glsa)

    table = glsa.generate_mail_table()

    expected = """
Package          Vulnerable               Unaffected
---------------  -----------------------  ------------------------
dev-lang/pypy3   < 7.3.9_p9               >= 7.3.9_p9
dev-lang/python  < 3.8.15_p3:3.8          >= 3.8.15_p3:3.8
                 < 3.9.15_p3:3.9          >= 3.9.15_p3:3.9
                 < 3.10.8_p3:3.10         >= 3.10.8_p3:3.10
                 < 3.11.0_p2:3.11         >= 3.11.0_p2:3.11
                 < 3.12.0_alpha1_p2:3.12  >= 3.12.0_alpha1_p2:3.12
""".strip()
    assert assert_diff(expected.splitlines(), table.splitlines())

    glsa = GLSA()
    glsa.affected = [
        Affected("net-libs/webkit-gtk", "2.40.5", "ge", "*", "4", "unaffected"),
        Affected("net-libs/webkit-gtk", "2.40.5", "ge", "*", "4.1", "unaffected"),
        Affected("net-libs/webkit-gtk", "2.40.5", "ge", "*", "6", "unaffected"),
        Affected("net-libs/webkit-gtk", "2.40.5", "lt", "*", "4", "vulnerable"),
    ]
    db.session.merge(glsa)

    table = glsa.generate_mail_table()

    expected = """
Package              Vulnerable    Unaffected
-------------------  ------------  -------------
net-libs/webkit-gtk  < 2.40.5:4    >= 2.40.5:4
                                   >= 2.40.5:4.1
                                   >= 2.40.5:6
""".strip()
    assert assert_diff(expected.splitlines(), table.splitlines())

    glsa = GLSA()
    glsa.affected = [
        Affected("www-client/firefox-bin", "102.12.0", "ge", "*", "esr", "unaffected"),
        Affected("www-client/firefox-bin", "102.12.0", "lt", "*", "esr", "unaffected"),
    ]
    db.session.merge(glsa)

    table = glsa.generate_mail_table()

    expected = """
Package                 Vulnerable    Unaffected
----------------------  ------------  ------------
www-client/firefox-bin                >= 102.12.0
""".strip()
    assert assert_diff(expected.splitlines(), table.splitlines())
