import difflib
import os

from sqlalchemy import create_engine

from glsamaker import release
from glsamaker import glsamaker
from glsamaker.app import app, db


app.jinja_loader.searchpath.append('glsamaker/templates')


glsa_xmls = ['test/files/glsa/glsa-202107-55.xml']


def file_contents(path):
    with open(path) as f:
        return f.read()


def test_generate_xml():
    db.create_all()
    for glsa_xml in glsa_xmls:
        glsa = glsamaker.xml_to_glsa(glsa_xml)
        glsa_contents = [x.strip() for x in file_contents(glsa_xml).splitlines()]
        with app.app_context():
            xml = [x.strip() for x in release.generate_xml(glsa).splitlines()]
            f = os.path.basename(glsa_xml)
            for x in difflib.unified_diff(glsa_contents, xml,
                                        fromfile='{}.test'.format(f),
                                        tofile=f):
                print(x)
            assert glsa_contents == release.generate_xml(glsa)
