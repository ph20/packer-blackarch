#!/usr/bin/env bash

echo "[+] Configure OpenVAS"
# configure redis
/usr/bin/sed -i 's|port 6379|port 0|' /etc/redis.conf
/usr/bin/sed -i 's|# unixsocket /tmp/redis.sock|unixsocket /tmp/redis.sock|' /etc/redis.conf
/usr/bin/sed -i 's|PrivateTmp=true|PrivateTmp=false|' /usr/lib/systemd/system/redis.service
cp -vr /vagrant/conf/service/* /usr/lib/systemd/system/
cp -vr /vagrant/conf/sysconfig/ /etc/
/bin/systemctl daemon-reload
/bin/systemctl enable redis.service
/bin/systemctl enable openvas-scanner.service
/bin/systemctl enable openvas-manager.service
/bin/systemctl enable gsad.service
/bin/openvasmd --create-user=admin --role=Admin
/bin/openvasmd --user=admin --new-password=admun
# deploing plugins database
/bin/wget http://dl.greenbone.net/community-nvt-feed-current.tar.bz2 /tmp/community-nvt-feed-current.tar.bz2
/bin/tar xf /tmp/community-nvt-feed-current.tar.bz2 -C /var/lib/openvas/plugins/
/bin/rm -f /tmp/community-nvt-feed-current.tar.bz2
/usr/bin/greenbone-nvt-sync

/usr/bin/greenbone-scapdata-sync
/usr/bin/greenbone-certdata-sync
/usr/bin/openvas-manage-certs -a -i
/bin/updatedb