#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-

"""
Script for get variable from var file
"""
import os
import sys
import json


class ExitErr(Exception):
    pass


def main():
    if len(sys.argv) == 3:
        var_key = sys.argv[2]
        json_file = sys.argv[1]
        if not os.path.exists(json_file):
            raise ExitErr('file "%s" exist' % json_file)
        with open(json_file) as file_:
            json_dict = json.load(file_)
        try:
            sys.stdout.write(json_dict[var_key])
        except KeyError:
            raise ExitErr('No such key "%s" in json file "%s"' % (var_key, json_file))
    else:
        raise ExitErr('Incorrect argument')


if __name__ == '__main__':
    try:
        main()
    except ExitErr as e:
        sys.stderr.write(str(e) + '\n')
        sys.exit(1)
