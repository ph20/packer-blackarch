#!/usr/bin/env python2
# -*- coding: utf-8 -*-

"""
Script for generating variables
"""

import os
import sys
import json
import datetime

import urllib2
from lxml import html as html


JSON_OUTPUT = os.path.join(os.path.dirname(__file__), 'variables.json')


def obtain_iso_url():
    """
    Parse information from official site
    """
    response = urllib2.urlopen('https://blackarch.org/downloads.html')
    content = response.read()
    tree = html.fromstring(content)
    subtree = tree.xpath('//table[@class="download"]/tr[contains(td[1], "BlackArch Linux 64 bit Netinstall ISO")]').pop()
    sha1sum = subtree.xpath('td[5]//text()').pop()
    iso_url = subtree.xpath('td[1]/a/@href').pop()
    return iso_url, sha1sum


def gen_vars():
    iso_url, sha1sum = obtain_iso_url()
    json_data = {
        'iso_url': iso_url,
        'iso_checksum': sha1sum,
        'created_at': datetime.date.today().strftime('%Y%m%d'),
        'headless': 'true'}
    return json_data

if __name__ == '__main__':
    json_data = gen_vars()

    with open(JSON_OUTPUT, 'w') as variables_file:
        json.dump(json_data, fp=variables_file, indent=4, sort_keys=True)
    sys.stdout.write(JSON_OUTPUT)
