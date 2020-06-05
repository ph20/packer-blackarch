#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script for obtaining fresh blackarch mirror list
"""

import sys
from datetime import datetime
from urllib.request import urlopen
from urllib.error import URLError

DOWNLOAD_PAGE = 'https://raw.githubusercontent.com/BlackArch/blackarch/master/mirror/mirror.lst'


class ExitException(Exception):
    pass


def get_last_update(url):
    if '$repo' in url:
        lastupdate_url = url[:url.index('$repo')] + 'lastupdate'
    else:
        print('WARNING: incorrect mirror url {}'.format(url))
        return
    lastupdate_timestamp = 0
    try:
        response = urlopen(lastupdate_url, timeout=25)
        lastupdate_timestamp = int(response.readline().decode().strip())
    except URLError as err:
        print('WARNING: can\'t obtain url "{}". {}'.format(lastupdate_url, str(err)))
    return lastupdate_timestamp


def obtain_blackarch_mirrors(out_path):
    try:
        response = urlopen(DOWNLOAD_PAGE, timeout=5)
        mirrors = response.read().decode()
    except URLError as e:
        raise ExitException(str(e) + ' ' + DOWNLOAD_PAGE)

    mirrors_list = []
    for mirrors_line in mirrors.split('\n'):
        if mirrors_line.count('|') == 2:
            mirror_url = mirrors_line.split('|')[1]
            mirrors_list.append((mirror_url, get_last_update(mirror_url)))

    with open(out_path, 'w') as mirror_file:
        mirror_file.write('# Mirror list generated at {}.\n'
                          '# Source {}\n'.format(datetime.now().strftime('%Y-%m-%d %H:%M:%S'), DOWNLOAD_PAGE))
        for mirror_url, lastupdate in sorted(mirrors_list, key=lambda _: _[1], reverse=True):
            if lastupdate:
                lastupdate_date = datetime.utcfromtimestamp(lastupdate).strftime('%Y-%m-%d %H:%M:%S')
                print('INFO: {} last update {}'.format(mirror_url, lastupdate_date))
                mirror_file.write('\n# sync date {}\nServer = {}\n'.format(lastupdate_date, mirror_url))
            else:
                print('WARNING: Mirror "{}" will bee skipped'.format(mirror_url))


if __name__ == '__main__':
    if len(sys.argv) != 2:
        sys.stderr.write('argument error; no path to output file\n')
        sys.exit(1)
    try:
        obtain_blackarch_mirrors(sys.argv[1])
    except ExitException as ex:
        sys.stderr.write("Can\'t open url: %s\n" % str(ex))
        sys.exit(1)
