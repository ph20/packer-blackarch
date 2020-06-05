#!/usr/bin/env bash
/usr/bin/sed -i 's/#X11Forwarding no/X11Forwarding yes/' /etc/ssh/sshd_config # enable X11 forwarding for run gui apps
#some fixes for correct installing all packages
#/usr/bin/pacman -S --noconfirm --overwrite --needed --quiet --noprogressbar --cachedir=/vagrant/pkg_cache python2-jsonschema

/usr/bin/pacman -S --noconfirm --overwrite="*" --needed --quiet --noprogressbar --cachedir=/vagrant/pkg_cache blackarch \
  --ignore=aiodnsbrute \
  --ignore=aztarna \
  --ignore=ctypes-sh \
  --ignore=ecfs \
  --ignore=elfutils \
  --ignore=gef \
  --ignore=ltrace \
  --ignore=rapidscan \
  --ignore=ropper \
  --ignore=sn1per \
  --ignore=sysdig \
  --ignore=theharvester \
  --ignore=valabind