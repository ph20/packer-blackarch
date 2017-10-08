#!/usr/bin/env python2
# -*- coding: utf-8 -*-

"""
Script for obtain fresh mirrors from https://www.archlinux.org/mirrorlist/all/
"""

import sys
try:
    import urllib2
except ImportError, ex:
    urllib2 = None
    sys.stderr.write("urllib2 absent: %s\n" % str(ex))
    sys.exit(1)


DOWNLOAD_PAGE = 'https://www.archlinux.org/mirrorlist/all/'


class ExitException(Exception):
    pass


def obtain_archlinux_mirrors(out_path):
    try:
        response = urllib2.urlopen(DOWNLOAD_PAGE, timeout=5)
        mirrors = response.read()
    except urllib2.URLError as e:
        raise ExitException(str(e) + ' ' + DOWNLOAD_PAGE)

    prev_line = ''
    with open(out_path, 'w') as mirror_file:
        for line in mirrors.split('\n'):
            if line.startswith('#Server = http') \
                    and not prev_line.startswith('#Server = http') \
                    and not prev_line.startswith('Server = http'):
                line_ = line[1:]
            else:
                line_ = line
            prev_line = line
            mirror_file.write(line_ + '\n')


if __name__ == '__main__':
    if len(sys.argv) != 2:
        sys.stderr.write('argument error; no path to output file\n')
        sys.exit(1)
    try:
        obtain_archlinux_mirrors(sys.argv[1])
    except ExitException, ex:
        sys.stderr.write("Can\'t open url: %s\n" % str(ex))
        sys.exit(1)
