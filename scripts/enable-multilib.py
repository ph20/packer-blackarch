#!/usr/bin/env python2
# -*- coding: utf-8 -*-

import os
import shutil

PACMAN_CONF = '/etc/pacman.conf'
PACMAN_CONF_TMP = PACMAN_CONF + '.tmp_'
PACMAN_CONF_BACK = PACMAN_CONF + '.back'

SECTION = '[multilib]'
OPTION = 'Include = /etc/pacman.d/mirrorlist'


def main():
    already_present = False
    data = ''
    with open(PACMAN_CONF) as input_:
        with open(PACMAN_CONF_TMP, 'w') as out:
            for line in input_:
                out.write(line)
                already_present |= line.startswith(SECTION)
            if not already_present:
                data = os.linesep + SECTION + os.linesep + OPTION + os.linesep
                out.write(data)

    if not already_present:
        shutil.copy(PACMAN_CONF, PACMAN_CONF_BACK)
        os.unlink(PACMAN_CONF)
        shutil.move(PACMAN_CONF_TMP, PACMAN_CONF)
        print('#--------------{}#-------------- \n# Added to "{}"'.format(data, PACMAN_CONF))
    else:
        print('Not need modify {}: "{}" section already present'.format(PACMAN_CONF, SECTION))


if __name__ == '__main__':
    try:
        main()
    except IOError as err:
        print(str(err))
        exit(1)




