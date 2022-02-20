from glsamaker.app import db
from glsamaker.models.glsa import GLSA
from glsamaker.models.reference import Reference

from util import assert_diff


def test_resolution_xml():
    glsa = GLSA()
    glsa.resolution = '''All SDL 2 users should upgrade to the latest version:

  # emerge --sync
  # emerge --ask --oneshot --verbose "&gt;=media-libs/libsdl2-2.0.14-r1"'''

    expected = '''<p>All SDL 2 users should upgrade to the latest version:</p>

<code>
  # emerge --sync
  # emerge --ask --oneshot --verbose "&gt;=media-libs/libsdl2-2.0.14-r1"
</code>'''

    assert assert_diff(expected.splitlines(), glsa.resolution_xml.splitlines())

    glsa.resolution = '''All Chromium users should upgrade to the latest version:

  # emerge --sync
  # emerge --ask --oneshot --verbose "&gt;=www-client/chromium-91.0.4472.164"

All Google Chrome users should upgrade to the latest version:

  # emerge --sync
  # emerge --ask --oneshot --verbose "&gt;=www-client/google-chrome-91.0.4472.164"'''

    expected = '''<p>All Chromium users should upgrade to the latest version:</p>

<code>
  # emerge --sync
  # emerge --ask --oneshot --verbose "&gt;=www-client/chromium-91.0.4472.164"
</code>

<p>All Google Chrome users should upgrade to the latest version:</p>

<code>
  # emerge --sync
  # emerge --ask --oneshot --verbose "&gt;=www-client/google-chrome-91.0.4472.164"
</code>'''

    assert assert_diff(expected.splitlines(), glsa.resolution_xml.splitlines())

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

    expected = '''<p>All Mozilla Firefox ESR users should upgrade to the latest version:</p>

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
</code>'''
    assert assert_diff(expected.splitlines(), glsa.resolution_xml.splitlines())


def test_get_references():
    glsa = GLSA()
    glsa.glsa_id = 'test glsa'
    cves = ['CVE-2021-4321', 'CVE-2021-1234']

    for text in cves:
        glsa.references.append(Reference.new(text))
    db.session.merge(glsa)

    assert glsa.get_reference_texts() == sorted(cves)
