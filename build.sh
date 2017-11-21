#!/usr/bin/env bash
source venv
FREE=`df -k --output=avail "$PWD" | tail -n1`   # df -k not df -h
if [[ $FREE -lt 26214400 ]]; then               # 25G = 25*1024*1024k
     echo "for building need ~25G free space"; exit 1;
fi;
python2 genvars.py $VAR_FILE || { echo 'generating variables failed' ; exit 1; }
CREATED_AT=$(python2 -c "import json; print(json.load(open('$VAR_FILE'))['created_at'])")
PACKER_TEMPLATE=blackarch-template.json
export BLACKARCH_PROFILE=core
packer-io build -var-file=$VAR_FILE -only=virtualbox-iso ${PACKER_TEMPLATE} && \
    vagrant up && \
    vagrant ssh --command='/usr/bin/sudo /bin/bash /vagrant/scripts/deploy-common.sh' && \
    vagrant ssh --command='/usr/bin/sudo /bin/bash /vagrant/scripts/configure.sh' && \
    vagrant ssh --command='/usr/bin/sudo /bin/bash /vagrant/scripts/cleanup.sh' && \
    vagrant package --output ./output/blackarch-common-${CREATED_AT}-x86_64-virtualbox.box && \
    vagrant up && \
    vagrant ssh --command='/usr/bin/sudo /bin/bash /vagrant/scripts/deploy-full.sh' && \
    vagrant ssh --command='/usr/bin/sudo /bin/bash /vagrant/scripts/cleanup.sh' && \
    vagrant package --output ./output/blackarch-full-${CREATED_AT}-x86_64-virtualbox.box
vagrant destroy -f
sleep 5
packer-io build -var-file=$VAR_FILE -only=qemu ${PACKER_TEMPLATE}