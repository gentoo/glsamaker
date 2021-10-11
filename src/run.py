#!/usr/bin/env python3

import os
from xml.etree import ElementTree

from db import Database
from glsa import GLSA
from website import app


def get_xml_text(xml_root, tag):
    tags = xml_root.findall(tag)

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


def get_xml_attrib(xml_root, tag):
    return xml_root.findall(tag)[0].attrib


def xml_to_glsa(xml):
    root = ElementTree.parse(xml).getroot()
    glsa = GLSA()
    glsa.id = root.attrib['id']
    glsa.title = get_xml_text(root, 'title')
    glsa.synopsis = get_xml_text(root, 'synopsis')
    glsa.product_type = get_xml_attrib(root, 'product')['type'].strip()
    glsa.product = get_xml_text(root, 'product')
    #glsa.announced = get_xml_text(root, 'announced').text
    #glsa.revision_count = get_xml_text(root, 'revised').attrib['count']
    #glsa.revised_date = get_xml_text(root, 'revised').text
    glsa.access = get_xml_text(root, 'access')
    glsa.background = get_xml_text(root, 'background')
    glsa.description = get_xml_text(root, 'description')
    glsa.impact_type = get_xml_attrib(root, 'impact')['type'].strip()
    glsa.impact = get_xml_text(root, 'impact')
    glsa.workaround = get_xml_text(root, 'workaround')
    glsa.resolution = get_xml_text(root, 'resolution')
    return glsa


def populate_glsa_db(db):
    glsa_xmls = [f for f in os.listdir('glsa')
                 if f.endswith('.xml')]
    for xml in glsa_xmls:
        app.logger.info("Ingesting {}".format(xml))
        with open(os.path.join('glsa', xml), 'r') as xml:
            glsa = xml_to_glsa(xml)
            db.update_glsa(GLSA, glsa)
    app.logger.info("Finished populating GLSA table")


if __name__ == "__main__":
    db = Database(app)
    populate_glsa_db(db)
    app.run(host='0.0.0.0', port=8080)
