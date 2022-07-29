import os
import tempfile

from glsamaker import main
from glsamaker.app import app, db
from glsamaker.models.glsa import GLSA
from glsamaker.models.reference import Reference

from util import assert_diff, gpghome, GPG_TEST_PASSPHRASE, SMTPUSER

import gnupg


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


def test_get_references():
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


app.jinja_loader.searchpath.append("glsamaker/templates")


glsas = ["test/files/glsa/glsa-202107-48", "test/files/glsa/glsa-202107-55"]


def striplines(lines):
    return [line.strip() for line in lines]


def file_contents(path):
    with open(path) as f:
        return f.readlines()


def test_generate_xml():
    # TODO: instead of diffing literal strings of XML, we should be
    # diffing actual xml contents.. somehow. Currently, we're often
    # testing for inconsequential whitespace differences
    for glsa_path in glsas:
        xml_path = "{}.xml".format(glsa_path)
        glsa = main.xml_to_glsa(xml_path)
        db.session.merge(glsa)
        glsa_contents = striplines(file_contents(xml_path))
        with app.app_context():
            xml = striplines(glsa.generate_xml().splitlines())
            assert assert_diff(glsa_contents, xml)


def test_generate_mail():
    for glsa_path in glsas:
        xml_path = "{}.xml".format(glsa_path)
        mail_path = "{}.mail".format(glsa_path)
        glsa = main.xml_to_glsa(xml_path)
        db.session.merge(glsa)
        mail_contents = [line.strip("\n") for line in file_contents(mail_path)]
        with app.app_context():
            time = "Fri, 23 Jul 2021 22:10:35 -0500"
            generated_mail = (
                glsa.generate_mail(
                    date=time, smtpuser=SMTPUSER, replyto="security@gentoo.org"
                )
                .as_message()
                .as_string()
                .splitlines()
            )
            assert assert_diff(mail_contents, generated_mail)


# https://gist.github.com/angelsenra/60397a72f29e58a7a4c27ed80c6c62d9
def test_generate_mail_signed(gpghome):
    gpg = gnupg.GPG(gnupghome=gpghome)
    subkey_fprint = list(gpg.list_keys()[0]["subkey_info"].keys())[0]
    with app.app_context():
        # Doesn't matter which GLSA we use here, we only need
        # something that will generate the mail properly as we're not
        # testing just how properly it's generated.
        glsa = main.xml_to_glsa(f"{glsas[0]}.xml")
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
