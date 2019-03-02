#!/usr/bin/env bash

ROOT=$1
#$CONF_DIR
# path to blackarch-installer
BI_PATH="/usr/share/blackarch-installer"
PACSTRAP=/usr/bin/pacstrap
CHROOT=/usr/bin/arch-chroot

# Chek all needed requrenents
NED_EXIT=0
if [ ! -f ${PACSTRAP} ]; then
    echo "File '${PACSTRAP}' not found! You should install arch-install-scripts package"
    NED_EXIT=1
fi
if [ ! -f ${CHROOT} ]; then
    echo "File '${CHROOT}' not found! You should install arch-install-scripts package"
    NED_EXIT=1
fi

#if [ ! -f ${BI_PATH} ]; then
#    echo "Directory '${BI_PATH}' not found!"
#    NED_EXIT=1
#fi
#if [ $NED_EXIT = 1 ]; then exit 1; fi
if [ -z ${CONF_DIR+x} ]; then echo "CONF_DIR is unset"; else echo "variable CONF_DIR is set to '$CONF_DIR'"; fi

if [ -f ${ROOT} ]; then
    echo "Directory '${ROOT}' already exist!"
    exit 1
fi

echo "[+] Installing ArchLinux base packages"
# install ArchLinux base and base-devel packages
#/usr/bin/pacstrap -c ${ROOT} base > /dev/null
mkdir ${ROOT}
/usr/bin/pacstrap -c ${ROOT} base base-devel ruby-pkg-config cmake gcc-multilib
# configure pacman and mirrors
cp --force /etc/pacman.conf ${ROOT}/etc/pacman.conf
cp /etc/pacman.d/mirrorlist ${ROOT}/etc/pacman.d/mirrorlist
${CONF_DIR}/pacman-opt.py ${ROOT}/etc/pacman.conf multilib Include /etc/pacman.d/mirrorlist  # enable multilib in pacman config
cp --force ${CONF_DIR}/blackarch-mirrorlist-cust ${ROOT}/etc/pacman.d/blackarch-mirrorlist-cust && \
    ${CONF_DIR}/pacman-opt.py ${ROOT} blackarch Include /etc/pacman.d/blackarch-mirrorlist-cust
/usr/bin/pacman -Syy --overwrite --quiet --noprogressbar --root ${ROOT}
#/usr/bin/arch-chroot ${ROOT} pacman -S --noconfirm  --quiet --noprogressbar --needed base-devel ruby-pkg-config cmake > /dev/null
/usr/bin/pacman -S --noconfirm --overwrite --needed --quiet --noprogressbar archlinux-keyring --root ${ROOT}
# replace gcc to gcc-multilib
#/usr/bin/arch-chroot ${ROOT} bash -c "yes | pacman -S --quiet --noprogressbar --needed gcc-multilib > /dev/null"

echo "[+] Start customisyng bootstrap"
#echo "[+] Updating /etc files"
#cp -r ${BI_PATH}/data/etc/. ${ROOT}/etc/.
#cp -r ${BI_PATH}/data/root/. ${ROOT}/root/.

#/usr/bin/arch-chroot ${ROOT} pacman -S --noconfirm --quiet --noprogressbar gptfdisk openssh syslinux > /dev/null
#/usr/bin/arch-chroot ${ROOT} syslinux-install_update -i -a -m
#/usr/bin/sed -i "s|sda3|${ROOT_PART##/dev/}|" "${ROOT}/boot/syslinux/syslinux.cfg"
#/usr/bin/sed -i 's/TIMEOUT 50/TIMEOUT 10/' "${ROOT}/boot/syslinux/syslinux.cfg"
#echo '[+] Generating the filesystem table'
#/usr/bin/genfstab -p ${ROOT} >> "${ROOT}/etc/fstab"

# sync disk
sync