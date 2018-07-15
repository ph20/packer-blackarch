#!/usr/bin/env bash
/usr/bin/sed -i 's/#X11Forwarding no/X11Forwarding yes/' /etc/ssh/sshd_config # enable X11 forwarding for run gui apps
/usr/bin/pacman -S --noconfirm --overwrite --needed --quiet --noprogressbar --cachedir=/vagrant/pkg_cache blackarch