#!/usr/bin/env bash
# Script for automaticaly deploy and configure OpenVAS on BlackArch

/usr/bin/pacman -S --noconfirm --overwrite --needed --quiet --noprogressbar --cachedir=/vagrant/pkg_cache \
    blackarch/openvas blackarch/greenbone-security-assistant blackarch/gvmd \
    python2 python3


/usr/bin/gvm-manage-certs -a
cp /vagrant/conf/openvas-manager.service /etc/systemd/system/openvas-manager.service
chmod 644 /etc/systemd/system/openvas-manager.service
/usr/bin/gvmd --create-user openvasadmin --password=openvasadmin
/bin/systemctl daemon-reload
/bin/systemctl enable openvas-manager.service
# Redis
cp /etc/redis.conf /etc/redis.conf_orig
/vagrant/conf/redis-conf.py /etc/redis.conf unixsocket /var/run/redis/redis.sock
/vagrant/conf/redis-conf.py /etc/redis.conf port 0
/bin/systemctl enable redis.service

/usr/bin/greenbone-nvt-sync
cp /vagrant/conf/openvassd.conf /etc/openvas/openvassd.conf
/usr/bin/sed -i 's|GSA_ADDRESS=127.0.0.1|GSA_ADDRESS=0.0.0.0|' /usr/etc/default/gsad

/bin/systemctl enable openvas.service
/bin/systemctl enable gsad.service
