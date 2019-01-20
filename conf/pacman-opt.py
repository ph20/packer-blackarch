#!/usr/bin/env python2
# -*- coding: utf-8 -*-

import os
import shutil
import sys
import re

SECTION_PATTERN = re.compile(r'\[([^\]]+)\]')
PACMAN_CONF = '/etc/pacman.conf'
PACMAN_CONF_TMP = PACMAN_CONF + '.tmp_'
PACMAN_CONF_BACK = PACMAN_CONF + '.back'


def section_iterator(input_):
    section_ = None
    output_ = []
    for line in input_:
        matched = SECTION_PATTERN.match(line)
        if matched:
            yield output_, section_
            output_ = []
            section_ = matched.group(1)
        output_.append(line)
    yield output_, section_


def main(section, option_, option_val_):
    was_modified = False
    with open(PACMAN_CONF) as input_:
        with open(PACMAN_CONF_TMP, 'w') as out:
            sections_present = False
            option_present = False
            for section_data, section_name in section_iterator(input_):
                if section == section_name:
                    sections_present = True
                    for line in section_data:
                        if not line.startswith('#'):
                            if '=' in line:
                                optin_name, optin_val = line.split('=', 2)
                            else:
                                optin_name, optin_val = line, ''
                            if (optin_name.strip(), optin_val.strip()) == (option_, option_val_):
                                option_present = True
                        out.write(line)
                    if not option_present:
                        out.write('{} = {}\n'.format(option_, option_val_))
                        was_modified = True
                else:
                    out.writelines(section_data)

            if not sections_present:
                section_string = '\n[{section}]\n' \
                                 '{option_name} = {option_val}\n'.format(section=section, option_name=option_,
                                                                         option_val=option_val_)
                out.write(section_string)
                was_modified = True
                print('#--------------{}#-------------- # Added to "{}"'.format(section_string, PACMAN_CONF))
            elif option_present:
                print('Not need modify {}: "{}" section already present'.format(PACMAN_CONF, section))

    if was_modified:
        shutil.copyfile(PACMAN_CONF, PACMAN_CONF_BACK)
        shutil.copyfile(PACMAN_CONF_TMP, PACMAN_CONF)
    os.unlink(PACMAN_CONF_TMP)


if __name__ == '__main__':
    argv_ = sys.argv[1:]
    if len(argv_) != 3:
        print('Arguments error. Usage: "pacman-opt.py  option option_value"", for example: '
              '"pacman-opt.py multilib Include /etc/pacman.d/mirrorlist"')
        exit(1)
    try:
        SECTION, OPPTION_NAME, OPTION_VAL = argv_
        main(SECTION, OPPTION_NAME, OPTION_VAL)
    except IOError as err:

        print(str(err))
        exit(1)




