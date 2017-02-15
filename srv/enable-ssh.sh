#!/usr/bin/env bash

PASSWORD=$(/usr/bin/openssl passwd -crypt 'vagrant')


echo "==> Installing sudo"
pacman -Syy --quiet
pacman -S --quiet --noconfirm sudo

echo "==> Enabling SSH"
# Vagrant-specific configuration
/usr/bin/useradd --password ${PASSWORD} --comment 'Packer User' --create-home --user-group vagrant
echo 'Defaults env_keep += "SSH_AUTH_SOCK"' > /etc/sudoers.d/10_vagrant
echo 'vagrant ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/10_vagrant
/usr/bin/chmod 0440 /etc/sudoers.d/10_vagrant
/usr/bin/systemctl start sshd.service
