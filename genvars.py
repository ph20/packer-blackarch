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

DOWNLOAD_PAGE = 'https://blackarch.org/downloads.html'


class ExitException(Exception):
    pass


def obtain_iso_url():
    """
    Parse information from official site
    """
    try:
        response = urllib2.urlopen(DOWNLOAD_PAGE, timeout=5)
        content = response.read()
    except urllib2.URLError as e:
        raise ExitException(str(e) + ' ' + DOWNLOAD_PAGE)
    tree = html.fromstring(content)
    try:
        subtree = tree.xpath('//table[@class="download"]/tr[contains(td[1], "BlackArch Linux 64 bit Netinstall ISO")]').pop()
        sha1sum = subtree.xpath('td[5]//text()').pop()
        iso_url = subtree.xpath('td[1]/a/@href').pop()
    except IndexError:
        raise ExitException("Can't parse content on '{}' for obtaining iso url".format(DOWNLOAD_PAGE))
    return iso_url, sha1sum


def gen_vars():
    iso_url, sha1sum = obtain_iso_url()
    return {
        'iso_url': iso_url,
        'iso_checksum': sha1sum,
        'created_at': datetime.date.today().strftime('%Y%m%d'),
        'headless': 'true'}


if __name__ == '__main__':
    try:
        json_data = gen_vars()
    except ExitException as e:
        sys.stderr.write(str(e) + os.linesep)
        sys.exit(1)
    except KeyboardInterrupt:
        sys.stderr.write('generating variables aborted')
        sys.exit(1)
    if len(sys.argv) == 2:
        with open(sys.argv[1], 'w') as variables_file:
            json.dump(json_data, fp=variables_file, indent=4, sort_keys=True)
    elif len(sys.argv) == 1:
        sys.stdout.write(json_data)
    else:
        sys.stderr.write('Incorrect arguments\n')
        sys.exit(1)
