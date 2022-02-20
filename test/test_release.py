import os

from sqlalchemy import create_engine

from glsamaker import release
from glsamaker import main
from glsamaker.app import app, db

from util import assert_diff


app.jinja_loader.searchpath.append('glsamaker/templates')


glsas = ['test/files/glsa/glsa-202107-48', 'test/files/glsa/glsa-202107-55']


def striplines(lines):
    return [line.strip() for line in lines]


def file_contents(path):
    with open(path) as f:
        return f.readlines()


def test_generate_xml():
    # TODO: instead of diffing literal strings of XML, we should be
    # diffing actual xml contents.. somehow. Currently, we're often
    # testing for inconsequential whitespace differences
    db.create_all()
    for glsa_path in glsas:
        xml_path = '{}.xml'.format(glsa_path)
        glsa = main.xml_to_glsa(xml_path)
        db.session.merge(glsa)
        glsa_contents = striplines(file_contents(xml_path))
        with app.app_context():
            xml = striplines(release.generate_xml(glsa).splitlines())
            f = os.path.basename(xml_path)
            assert assert_diff(glsa_contents, xml)


def test_generate_mail():
    for glsa_path in glsas:
        xml_path = '{}.xml'.format(glsa_path)
        mail_path = '{}.mail'.format(glsa_path)
        glsa = main.xml_to_glsa(xml_path)
        db.session.merge(glsa)
        mail_contents = [line.strip('\n') for line in file_contents(mail_path)]
        with app.app_context():
            time = 'Fri, 23 Jul 2021 22:10:35 -0500'
            generated_mail = release.generate_mail(glsa, time).splitlines()
            f = os.path.basename(mail_path)
            assert assert_diff(mail_contents, generated_mail)
