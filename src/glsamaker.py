#!/usr/bin/env python3

from datetime import datetime
import os
from xml.etree import ElementTree

from app import app, db
from models.bug import Bug
from models.glsa import GLSA
from models.reference import Reference
from models.user import User, nick_to_uid, create_user
import views


def get_xml_text(xml_root, match):
    tags = xml_root.findall(match)

    # Sometimes GLSAs don't have all of the fields they should
    if len(tags) == 0:
        return ""

    # Need to be able to handle the case in glsa-201608-01 where the
    # <product> is empty, so text will be None and would error on
    # on .strip()
    text = tags[0].text

    if text:
        return text.strip()
    return text


def get_xml_attrib(xml_root, match):
    tags = xml_root.findall(match)
    if len(tags) > 0:
        return xml_root.findall(match)[0].attrib
    return None


def xml_to_glsa(xml):
    root = ElementTree.parse(xml).getroot()
    glsa = GLSA()
    glsa.glsa_id = root.attrib['id']
    glsa.title = get_xml_text(root, 'title')
    glsa.synopsis = get_xml_text(root, 'synopsis')
    glsa.product_type = get_xml_attrib(root, 'product')['type'].strip()
    glsa.product = get_xml_text(root, 'product')
    glsa.announced = datetime.fromisoformat(get_xml_text(root, 'announced'))
    glsa.revision_count = get_xml_attrib(root, 'revised')['count']
    glsa.revised_date = datetime.fromisoformat(get_xml_text(root, 'revised'))

    for bug in root.findall('bug'):
        glsa.bugs.append(Bug(bug.text))

    glsa.access = get_xml_text(root, 'access')
    glsa.background = get_xml_text(root, 'background')
    glsa.description = get_xml_text(root, 'description')
    glsa.impact_type = get_xml_attrib(root, 'impact')['type'].strip()
    glsa.impact = get_xml_text(root, 'impact')
    glsa.workaround = get_xml_text(root, 'workaround')
    glsa.resolution = get_xml_text(root, 'resolution')

    for uri in root.find('references'):
        glsa.references.append(Reference(uri.text.strip(), uri.attrib['link']))

    requester = get_xml_text(root, './/metadata[@tag="requester"]')
    submitter = get_xml_text(root, './/metadata[@tag="submitter"]')

    if not User.query.filter(User.nick == requester).first():
        create_user(requester)

    if not User.query.filter(User.nick == submitter).first():
        create_user(submitter)

    glsa.requester = nick_to_uid(requester)
    glsa.submitter = nick_to_uid(submitter)

    # Handle these conditionally because not all GLSAs have these fields
    requested_tag = get_xml_attrib(root, './/metadata[@tag="requester"]')
    if requested_tag and 'timestamp' in requested_tag:
        glsa.requested_time = datetime.fromisoformat(requested_tag['timestamp'].rstrip('Z'))

    submitted_tag = get_xml_attrib(root, './/metadata[@tag="submitter"]')
    if submitted_tag and 'timestamp' in submitted_tag:
        glsa.submitted_time = datetime.fromisoformat(submitted_tag['timestamp'].rstrip('Z'))

    return glsa


def populate_glsa_db():
    glsa_xmls = [f for f in os.listdir('glsa')
                 if f.endswith('.xml')]
    app.logger.info("Checking for new GLSAs")
    for xml in glsa_xmls:
        # The GLSA IDs in the database are formatted like
        # yyyymm-xx, so we need to transform the filename into this
        # format before checking the db for its existence
        glsa = os.path.splitext(xml)[0].replace('glsa-', '')
        if not GLSA.query.filter(GLSA.glsa_id == glsa).first():
            app.logger.debug("Ingesting {}".format(xml))
            with open(os.path.join('glsa', xml), 'r') as xml:
                glsa = xml_to_glsa(xml)
                db.session.merge(glsa)
    db.session.commit()
    app.logger.info("Finished populating GLSA table")


if __name__ == "__main__":
    db.create_all()
    populate_glsa_db()
    app.run(host='0.0.0.0', port=8080)
