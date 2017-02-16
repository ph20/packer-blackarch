#!/usr/bin/env bash


HOST_NAME="blackarch-box"

################################################################################
# true / false
TRUE=0
FALSE=1

# return codes
SUCCESS=0
FAILURE=1

# colors
WHITE="`tput setaf 7`"
WHITEB="`tput bold ; tput setaf 7`"
GREEN="`tput setaf 2`"
GREENB="`tput bold ; tput setaf 2`"
RED="`tput setaf 1`"
REDB="`tput bold; tput setaf 1`"
YELLOW="`tput setaf 3`"
YELLOWB="`tput bold ; tput setaf 3`"
BLINK="`tput blink`"
NC="`tput sgr0`"

PACKER_BUILDER_TYPE='qemu'
CHROOT="/mnt"

# strap shell information
STRAP_URL="https://www.blackarch.org/strap.sh"
STRAP_SHA1="34b1a3698a4c971807fb1fe41463b9d25e1a4a09"
STRAP_SH="/root/strap.sh"
# path to blackarch-installer
BI_PATH="/usr/share/blackarch-installer"

LANGUAGE='en_US.UTF-8'
KEYMAP='us'
TIMEZONE='UTC'
CONFIG_SCRIPT='/usr/local/bin/arch-config.sh'

# stop on errors
set -eu
PASSWORD=$(/usr/bin/openssl passwd -crypt 'vagrant')
if [[ $PACKER_BUILDER_TYPE == "qemu" ]]; then
	DISK='/dev/vda'
else
	DISK='/dev/sda'
fi
ROOT_PART="${DISK}1"

# print formatted output
wprintf()
{
    fmt="${1}"

    shift
    printf "%s${fmt}%s" "${WHITE}" "${@}" "${NC}"

    return $SUCCESS
}

# print error and exit
err()
{
    printf "%s[-] ERROR: %s%s\n" "${RED}" "${@}" "${NC}"
    exit $FAILURE

    return $SUCCESS
}

check_env()
{
    if [ `id -u` -ne 0 ]
    then
        err "You must be root to run the BlackArch installer!"
    fi
    if [ -f "/var/lib/pacman/db.lck" ]
    then
        err "pacman locked - Please remove /var/lib/pacman/db.lck"
    fi
    if ! curl -s "http://www.google.com/" > /dev/null
    then
        err "No Internet connection! Check your network (settings)."
    fi
    curl -s -o "${STRAP_SH}" ${STRAP_URL}
    sha1=`sha1sum ${STRAP_SH} | awk '{print $1}'`
    if [ "${sha1}" -ne ${STRAP_SHA1} ]
    then
        err "Wrong SHA1 sum for ${STRAP_URL}: ${sha1} (orig: ${STRAP_SHA1}). Aborting!"
    fi
}


enable_multilib()
{
# enable multilib in pacman.conf if x86_64 present
if [ "`uname -m`" = "x86_64" ]
then
    wprintf "[+] Enabling multilib support"
    if grep -q "#\[multilib\]" /etc/pacman.conf
    then
        # it exists but commented
        sed -i '/\[multilib\]/{ s/^#//; n; s/^#//; }' /etc/pacman.conf
    elif ! grep -q "\[multilib\]" /etc/pacman.conf
    then
        # it does not exist at all
        printf "[multilib]\nInclude = /etc/pacman.d/mirrorlist\n" \
            >> /etc/pacman.conf
    fi
fi
}

prepare_env()
{
    localectl set-keymap --no-convert us  # set keymap to use
    # enable color mode in pacman.conf
    sed -i 's/^#Color/Color/' /etc/pacman.conf
    enable_multilib
    # update pacman package database
    wprintf "[+] Updating pacman database"
    pacman -Syy --noconfirm
    pacman -S --noconfirm gptfdisk
    return $SUCCESS

}


prepare_disk()
{
    # make and format partitions
    wprintf "==> Clearing partition table on ${DISK}"
    /usr/bin/sgdisk --zap ${DISK}
    wprintf "==> Destroying magic strings and signatures on ${DISK}"
    /usr/bin/dd if=/dev/zero of=${DISK} bs=512 count=2048
    /usr/bin/wipefs --all ${DISK}
    wprintf "==> Creating /root partition on ${DISK}"
    /usr/bin/sgdisk --new=1:0:0 ${DISK}
    wprintf "==> Setting ${DISK} bootable"
    /usr/bin/sgdisk ${DISK} --attributes=1:set:2
    wprintf '[+] Creating /root filesystem (ext4)'
    /usr/bin/mkfs.ext4 -O ^64bit -F -m 0 -q -L root ${ROOT_PART}
}

mount_filesystem()
{
    wprintf "==> Mounting ${ROOT_PART} to ${CHROOT}"
    /usr/bin/mount -o noatime,errors=remount-ro ${ROOT_PART} ${CHROOT}
}

umount_filesystem()
{
    wprintf "[+] Unmounting filesystems"
    umount -Rf ${CHROOT} > /dev/null 2>&1
}

install_base()
{
    wprintf "[+] Installing ArchLinux base packages"
    # install ArchLinux base and base-devel packages
    pacstrap ${CHROOT} base base-devel
    /usr/bin/arch-chroot ${CHROOT} pacman -Syy --force
    wprintf "[+] Updating /etc files"
    cp -r ${BI_PATH}/data/etc/. ${CHROOT}/etc/.
    /usr/bin/arch-chroot ${CHROOT} pacman -S --noconfirm gptfdisk openssh syslinux
    /usr/bin/arch-chroot ${CHROOT} syslinux-install_update -i -a -m
    /usr/bin/sed -i "s|sda3|${ROOT_PART##/dev/}|" "${CHROOT}/boot/syslinux/syslinux.cfg"
    /usr/bin/sed -i 's/TIMEOUT 50/TIMEOUT 10/' "${CHROOT}/boot/syslinux/syslinux.cfg"
    cp ${BI_PATH}/data/boot/grub/splash.png ${CHROOT}/boot/grub/splash.png | true
    wprintf '[+] Generating the filesystem table'
    /usr/bin/genfstab -p ${CHROOT} >> "${CHROOT}/etc/fstab"
}

run_strap()
{
    cp ${STRAP_SH} "${CHROOT}${STRAP_SH}"
    chmod a+x "${CHROOT}${STRAP_SH}"
    # add blackach repo for prevent input wait in strap shell
    echo '[blackarch]' >> "${CHROOT}/etc/pacman.conf"
    echo 'Server = https://www.mirrorservice.org/sites/blackarch.org/blackarch/$repo/os/$arch' >> "${CHROOT}/etc/pacman.conf"

    #/usr/bin/arch-chroot ${CHROOT} /bin/bash ${STRAP_SH}
    # sync disk
    sync
}

configure_system(){
wprintf '[+] Generating the system configuration script'
/usr/bin/install --mode=0755 /dev/null "${CHROOT}${CONFIG_SCRIPT}"
cp /etc/udev/rules.d/81-dhcpcd.rules "${CHROOT}/etc/udev/rules.d/81-dhcpcd.rules"

cat <<-EOF > "${CHROOT}${CONFIG_SCRIPT}"
    #!/bin/sh
    # stop on errors
    set -eu
	echo '${HOST_NAME}' > /etc/hostname
	/usr/bin/ln -f -s /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
	echo 'KEYMAP=${KEYMAP}' > /etc/vconsole.conf
	/usr/bin/sed -i 's/#${LANGUAGE}/${LANGUAGE}/' /etc/locale.gen
	/usr/bin/locale-gen
	/usr/bin/mkinitcpio -p linux
	/usr/bin/usermod --password ${PASSWORD} root
	# https://wiki.archlinux.org/index.php/Network_Configuration#Device_names
	#/usr/bin/ln -s /dev/null /etc/udev/rules.d/80-net-setup-link.rules
	#/usr/bin/ln -s '/usr/lib/systemd/system/dhcpcd@.service' '/etc/systemd/system/multi-user.target.wants/dhcpcd@eth0.service'
	/usr/bin/sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
	/usr/bin/systemctl enable sshd.service

	# Vagrant-specific configuration
	/usr/bin/useradd --password ${PASSWORD} --comment 'Vagrant User' --create-home --user-group vagrant
	echo 'Defaults env_keep += "SSH_AUTH_SOCK"' > /etc/sudoers.d/10_vagrant
	echo 'vagrant ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/10_vagrant
	/usr/bin/chmod 0440 /etc/sudoers.d/10_vagrant
	/usr/bin/install --directory --owner=vagrant --group=vagrant --mode=0700 /home/vagrant/.ssh
	/usr/bin/curl --output /home/vagrant/.ssh/authorized_keys --location https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub
	/usr/bin/chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys
	/usr/bin/chmod 0600 /home/vagrant/.ssh/authorized_keys

	# clean up
	/usr/bin/pacman -Rcns --noconfirm gptfdisk
EOF


wprintf '[+] Entering chroot and configuring system'
/usr/bin/arch-chroot ${CHROOT} /bin/bash ${CONFIG_SCRIPT}
rm "${CHROOT}${CONFIG_SCRIPT}"

# http://comments.gmane.org/gmane.linux.arch.general/48739
wprintf '[+] Adding workaround for shutdown race condition'
/usr/bin/install --mode=0644 /root/poweroff.timer "${CHROOT}/etc/systemd/system/poweroff.timer"
}

main()
{
    check_env
    prepare_env
    prepare_disk
    mount_filesystem
    install_base
    run_strap
    configure_system
    umount_filesystem
    /usr/bin/systemctl reboot
}

main
