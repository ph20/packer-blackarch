#!/usr/bin/env bash
VAR_FILE=$(python2 genvars.py)
packer-io build -var-file=$VAR_FILE -only=virtualbox-iso blackarch-template.json
packer-io build -var-file=$VAR_FILE -only=qemu blackarch-template.json