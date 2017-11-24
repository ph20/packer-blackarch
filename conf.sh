#!/usr/bin/env bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PACKER_VAR_FILE="$DIR/variables.json"
PACKER_TEMPLATE="$DIR/blackarch-template.json"
PACKER_OUTPUT="$DIR/output"
SCRIPTS="$DIR/scripts"
GENVAR=$SCRIPTS/genvars.py
GETVAR=$SCRIPTS/getvar.py