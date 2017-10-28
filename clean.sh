#!/usr/bin/env bash
VAR_FILE=./variables.json
CREATED_AT=$(python2 -c "import json; print(json.load(open('$VAR_FILE'))['created_at'])")
BOX_NAME="blackarch-core-${CREATED_AT}-x86_64"
vagrant destroy -f
vagrant box remove --force --box-version=0 --provider=virtualbox ${BOX_NAME}
vagrant box remove --force --box-version=0 --provider=libvirt ${BOX_NAME}
rm -Rf ./output/*.box ./packer_cache/ ./.vagrant/ ./variables.json