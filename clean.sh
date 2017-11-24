#!/usr/bin/env bash
source conf.sh
CREATED_AT=$(python2.7 $PACKER_VAR_FILE $GETVAR created_at) || { exit 1; }
BOX_NAME="blackarch-core-${CREATED_AT}-x86_64"
vagrant destroy -f
vagrant box remove --force --box-version=0 --provider=virtualbox ${BOX_NAME}
vagrant box remove --force --box-version=0 --provider=libvirt ${BOX_NAME}
rm -Rf $PACKER_OUTPUT/*.box $DIR/packer_cache/ $DIR/.vagrant/ $PACKER_VAR_FILE