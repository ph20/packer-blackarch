#!/usr/bin/env bash
FREE=`df -k --output=avail "$PWD" | tail -n1`   # df -k not df -h
if [[ $FREE -lt 26214400 ]]; then               # 25G = 25*1024*1024k
     echo "for building need ~25G free space"; exit 1;
fi;
VAR_FILE=$(python2 genvars.py) || { echo 'generating variables failed' ; exit 1; }
packer-io build -var-file=$VAR_FILE -only=virtualbox-iso blackarch-template.json
packer-io build -var-file=$VAR_FILE -only=qemu blackarch-template.json