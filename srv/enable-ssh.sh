#!/usr/bin/env bash

echo "==> Enabling SSH"
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config # enable root login with password
/usr/bin/systemctl start sshd.service
/usr/bin/systemctl enable sshd.service
