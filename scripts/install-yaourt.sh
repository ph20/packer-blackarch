#!/usr/bin/env bash
# You should run this script under vagrant user

/usr/bin/sudo /usr/bin/pacman -S --noconfirm --needed --quiet --noprogressbar --cachedir=/vagrant/pkg_cache base-devel git wget yajl
mkdir /tmp/yaouurt_build
cd /tmp/yaouurt_build
/bin/git clone https://aur.archlinux.org/package-query.git
cd package-query/
/bin/makepkg --noprogressbar --noconfirm --syncdeps --rmdeps --install
cd /tmp/yaouurt_build
git clone https://aur.archlinux.org/yaourt.git
cd yaourt/
/bin/makepkg --noprogressbar --noconfirm --syncdeps --rmdeps --install
rm -Rf /tmp/yaouurt_build