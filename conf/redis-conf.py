#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import shutil
import sys


"""
Util for simple change redis config
Usage:
<script> config/path.cfg keyword newargument
"""

SEP = ' '


def split_eol(line):
    eol_len = len(line.rstrip('\r\n')) - len(line)
    return line[:eol_len], line[eol_len:]


def main(path, keyword, newargument, commented=False):
    with open(path) as _:
        config = _.readlines()
    new_conf = []
    changed = False
    eol = '\n'
    for line_n, line in enumerate(config):
        if commented:
            line_ = line.lstrip('# ')
        else:
            line_ = line
        k_v = line_.split(sep=SEP, maxsplit=1)
        if len(k_v) == 2:
            k, v = k_v
            if k == keyword:
                val, eol = split_eol(v)
                new_line = k + SEP + newargument
                print('file {} line numb {}\n-{}\n+{}'.format(path, line_n, split_eol(line)[0], new_line))
                line = new_line + eol
                changed = True
        new_conf.append(line)

    if changed:
        try:
            with open(path, 'w') as _:
                _.writelines(new_conf)
        except PermissionError as e:
            print(e)
            exit(1)
    elif not commented:
        main(path=path, keyword=keyword, newargument=newargument, commented=True)
    else:
        with open(path, 'a') as _:
            _.write(keyword + SEP + newargument + eol)


if __name__ == '__main__':
    path, keyword, newargument = sys.argv[1:]
    main(path, keyword, newargument)





