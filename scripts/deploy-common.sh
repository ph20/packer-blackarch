#!/usr/bin/env bash
/usr/bin/sed -i 's/#X11Forwarding no/X11Forwarding yes/' /etc/ssh/sshd_config # enable X11 forwarding for run gui apps

/usr/bin/pacman -S --noconfirm --force --needed --quiet --noprogressbar --cachedir=/vagrant/pkg_cache yaourt mlocate net-tools strace vim
/bin/su vagrant --command "/bin/yaourt -S --noconfirm jre8"
/usr/bin/pacman -S --noconfirm --force --needed --quiet --noprogressbar --cachedir=/vagrant/pkg_cache \
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
    openvas-manager openvas-scanner gsa gsd openvas-cli greenbone-security-assistant python2 \
    zaproxy libxtst xorg-xauth \
    w3af dartspylru python2-jinja python2-tblib python2-pyasn1 halberd python2-markdown \
    burpsuite