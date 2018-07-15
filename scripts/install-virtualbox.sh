#!/usr/bin/bash -x

# VirtualBox Guest Additions
# https://wiki.archlinux.org/index.php/VirtualBox
echo "[+] Deploy virtualbox guest"
/sbin/mv --force /etc/xdg/autostart/vboxclient.desktop /etc/xdg/autostart/vboxclient.desktop.old || true  # conflict with virtualbox-guest-utils
/usr/bin/pacman -S --noconfirm linux-headers virtualbox-guest-utils virtualbox-guest-dkms nfs-utils
/usr/bin/systemctl enable vboxservice.service
/usr/bin/systemctl enable rpcbind.service

# Add groups for VirtualBox folder sharing
/usr/bin/groupadd vagrant
/usr/bin/usermod --append --groups vagrant,vboxsf vagrant
