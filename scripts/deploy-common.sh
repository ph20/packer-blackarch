#!/usr/bin/env bash
/usr/bin/sed -i 's/#X11Forwarding no/X11Forwarding yes/' /etc/ssh/sshd_config # enable X11 forwarding for run gui apps

/usr/bin/pacman -S --noconfirm --overwrite --needed --quiet --noprogressbar --cachedir=/vagrant/pkg_cache mlocate net-tools strace vim rsync
# Fix package-query: error while loading shared libraries: libalpm.so.10: cannot open shared object file: No such file or directory
ln -s /usr/lib/libalpm.so.11 /usr/lib/libalpm.so.10
/usr/bin/pacman -S --noconfirm --overwrite --needed --quiet --noprogressbar --cachedir=/vagrant/pkg_cache \
    sqlmap \
    nikto \
    nmap \
    hydra \
    medusa \
    metasploit \
    hping \
    wpscan \
    joomscan \
    masscan \
    zaproxy libxtst xorg-xauth \
    w3af python2-jinja python2-tblib python2-pyasn1 halberd python2-markdown \
    burpsuite