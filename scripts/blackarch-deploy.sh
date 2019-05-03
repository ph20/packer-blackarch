#!/usr/bin/env bash
# stop on errors
set -eu

HOST_NAME="blackarch-box"

################################################################################
# return codes
SUCCESS=0
FAILURE=1

CHROOT="/mnt"

# path to blackarch-installer
BI_PATH="/usr/share/blackarch-installer"

LANGUAGE='en_US.UTF-8'
KEYMAP='us'
TIMEZONE='UTC'
CONFIG_SCRIPT='/usr/local/bin/arch-config.sh'
SUDOUSERS_FILE=/etc/sudoers.d/10_vagrant
KERNEL=linux-lts
SCRIPT="/root/blackarch-deploy.sh"
USER_NAME=vagrant

echo "[+] Check environment for run deploying"
# check needed variables for running script
if [ -z ${PACKER_BUILDER_TYPE+x} ]; then  echo "\$PACKER_BUILDER_TYPE variable is unset"; exit $FAILURE;  fi

# check environment for run script
if [ `id -u` -ne 0 ]
then
    echo "You must be root to run the BlackArch packer installer!"; exit $FAILURE;
fi

if [ -f "/var/lib/pacman/db.lck" ]
then
    echo "pacman locked - Please remove /var/lib/pacman/db.lck"; exit $FAILURE;
fi

if ! curl -s "http://www.google.com/" > /dev/null
then
    echo "No Internet connection! Check your network (settings)."; exit $FAILURE;
fi

VAGRANT_PASSWORD=$(/usr/bin/openssl passwd -quiet  -crypt 'vagrant')
ROOT_PASSWORD=$(/usr/bin/openssl passwd -quiet  -crypt 'blackarch')
if [[ $PACKER_BUILDER_TYPE == "qemu" ]]; then
	DISK='/dev/vda'
else
	DISK='/dev/sda'
fi
ROOT_PART="${DISK}1"

install_script(){
/usr/bin/install --mode=0755 $0 "${CHROOT}${SCRIPT}"
}

prepare_env()
{
    localectl set-keymap --no-convert us  # set keymap to use

    # update pacman package database
    echo "[+] Updating pacman database"
    pacman -Syy --noconfirm --quiet --noprogressbar > /dev/null
    pacman -S --noconfirm  --quiet --noprogressbar --needed pacman-contrib gptfdisk patch rsync git> /dev/null

    echo "==> Choose mirrors with best speed"
    /usr/bin/cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.orig
    /usr/bin/rankmirrors -n 3 /etc/pacman.d/mirrorlist.orig > /etc/pacman.d/mirrorlist
    return $SUCCESS

}


prepare_disk()
{
    # make and format partitions
    echo "[+] Clearing partition table on ${DISK}"
    /usr/bin/sgdisk --zap ${DISK}
    echo "[+] Destroying magic strings and signatures on ${DISK}"
    /usr/bin/dd if=/dev/zero of=${DISK} bs=512 count=2048
    /usr/bin/wipefs --all ${DISK}
    echo "[+] Creating /root partition on ${DISK}"
    /usr/bin/sgdisk --new=1:0:0 ${DISK}
    echo "[+] Setting ${DISK} bootable"
    /usr/bin/sgdisk ${DISK} --attributes=1:set:2
    echo '[+] Creating /root filesystem (ext4)'
    /usr/bin/mkfs.ext4 -O ^64bit -F -m 0 -q -L root ${ROOT_PART}
}

mount_filesystem()
{
    echo "[+] Mounting ${ROOT_PART} to ${CHROOT}"
    /usr/bin/mount -o noatime,errors=remount-ro ${ROOT_PART} ${CHROOT}
}

umount_filesystem()
{
    echo "[+] Unmounting filesystems"
    # sync disk
    /usr/bin/sync
    /usr/bin/umount -Rf ${CHROOT} > /dev/null 2>&1
}

rsync_system(){
    echo "[+] Rsync current system '/' => '${CHROOT}'"
    /usr/bin/rsync -aAX --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/boot/*","/lost+found"} / ${CHROOT}
}

install_base()
{
    echo "[+] Installing ArchLinux base packages"
    # install ArchLinux base and base-devel packages
    /usr/bin/pacstrap ${CHROOT} base > /dev/null

    # configure pacman and mirrors
    cp --force /etc/pacman.conf ${CHROOT}/etc/pacman.conf
    cp /etc/pacman.d/mirrorlist ${CHROOT}/etc/pacman.d/mirrorlist
    /root/conf/pacman-opt.py multilib Include /etc/pacman.d/mirrorlist  # enable multilib in pacman config
    cp /etc/pacman.d/mirrorlist.orig ${CHROOT}/etc/pacman.d/mirrorlist.orig
    cp --force /root/conf/blackarch-mirrorlist-cust ${CHROOT}/etc/pacman.d/blackarch-mirrorlist-cust && \
        /root/conf/pacman-opt.py blackarch Include /etc/pacman.d/blackarch-mirrorlist-cust
    /usr/bin/arch-chroot ${CHROOT} pacman -Syy --overwrite --quiet --noprogressbar > /dev/null
    /usr/bin/arch-chroot ${CHROOT} pacman -S --noconfirm  --quiet --noprogressbar --needed base-devel ruby-pkg-config cmake > /dev/null
    /usr/bin/arch-chroot ${CHROOT} pacman -S --noconfirm --overwrite --needed --quiet --noprogressbar archlinux-keyring > /dev/null
    # replace gcc to gcc-multilib
    /usr/bin/arch-chroot ${CHROOT} bash -c "yes | pacman -S --quiet --noprogressbar --needed gcc-multilib > /dev/null"
    echo "[+] Updating /etc files"
    cp -r ${BI_PATH}/data/etc/. ${CHROOT}/etc/.
    cp -r ${BI_PATH}/data/root/. ${CHROOT}/root/.
    /usr/bin/arch-chroot ${CHROOT} pacman -S --noconfirm --quiet --noprogressbar gptfdisk openssh > /dev/null
}


make_bootable(){
    /usr/bin/arch-chroot ${CHROOT} pacman -R --noconfirm --noprogressbar linux > /dev/null | true
    /usr/bin/arch-chroot ${CHROOT} pacman -S --noconfirm --quiet --noprogressbar ${KERNEL} syslinux > /dev/null
    /usr/bin/arch-chroot ${CHROOT} syslinux-install_update -i -a -m
    /usr/bin/sed -i "s|sda3|${ROOT_PART##/dev/}|" "${CHROOT}/boot/syslinux/syslinux.cfg"
    /usr/bin/sed -i 's/TIMEOUT 50/TIMEOUT 10/' "${CHROOT}/boot/syslinux/syslinux.cfg"
    /usr/bin/sed -i "s/-linux/-${KERNEL}/" "${CHROOT}/boot/syslinux/syslinux.cfg"
    echo '[+] Generating the filesystem table'
    /usr/bin/genfstab -p ${CHROOT} >> "${CHROOT}/etc/fstab"
    /usr/bin/arch-chroot ${CHROOT} /usr/bin/mkinitcpio -p ${KERNEL}
}

add_vagrant_user(){
    USERADD_ARGS="--uid 1000"

    echo "[+] Adding user ${USER_NAME} => ${USERADD_ARGS}"
    /usr/sbin/useradd --password ${VAGRANT_PASSWORD} --comment 'Vagrant User' --create-home ${USERADD_ARGS} --user-group ${USER_NAME}
    if [ ! -f ${SUDOUSERS_FILE} ]; then
        echo 'Defaults env_keep += "SSH_AUTH_SOCK"' > ${SUDOUSERS_FILE}
    fi
    echo "${USER_NAME} ALL=(ALL) NOPASSWD: ALL" >> ${SUDOUSERS_FILE}
    /bin/chmod 0440 ${SUDOUSERS_FILE}
    /usr/bin/install --directory --owner=${USER_NAME} --group=${USER_NAME} --mode=0700 "/home/${USER_NAME}/.ssh"
    /usr/bin/curl -s --output "/home/${USER_NAME}/.ssh/authorized_keys" --location https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub
    /bin/chown ${USER_NAME}:${USER_NAME} "/home/${USER_NAME}/.ssh/authorized_keys"
    /bin/chmod 0600 "/home/${USER_NAME}/.ssh/authorized_keys"

}

add_vagrant_user_chroot(){
    /usr/bin/arch-chroot ${CHROOT} ${SCRIPT} add_vagrant_user
    cp -r ${BI_PATH}/data/user/. ${CHROOT}/home/vagrant/.  # customise vagrant environment
    /usr/bin/arch-chroot ${CHROOT} /bin/chown -R vagrant:vagrant /home/vagrant/
}

configure_system(){
	echo "${HOST_NAME}" > /etc/hostname
	/usr/bin/ln -f -s /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
	echo "KEYMAP=${KEYMAP}" > /etc/vconsole.conf
	/usr/bin/sed -i "s/#${LANGUAGE}/${LANGUAGE}/" /etc/locale.gen
	/usr/bin/locale-gen
	/usr/bin/usermod --password ${ROOT_PASSWORD} root
	# configure sshd
	/usr/bin/sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
	/usr/bin/sed -i 's/#UseDNS no/UseDNS no/' /etc/ssh/sshd_config
	/usr/bin/sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
	/usr/bin/systemctl enable sshd.service
}

configure_system_chroot(){
    echo '[+] Customise system'
    cp /etc/udev/rules.d/81-dhcpcd.rules "${CHROOT}/etc/udev/rules.d/81-dhcpcd.rules"
    /usr/bin/arch-chroot ${CHROOT} ${SCRIPT} configure_system
    # http://comments.gmane.org/gmane.linux.arch.general/48739
    echo '[+] Adding workaround for shutdown race condition'
    /usr/bin/install --mode=0644 /root/conf/poweroff.timer "${CHROOT}/etc/systemd/system/poweroff.timer"
    # restore original mirror list
    mv --force ${CHROOT}/etc/pacman.d/mirrorlist.orig ${CHROOT}/etc/pacman.d/mirrorlist
}

update(){
    echo "[+] Updating system"
    /usr/bin/pacman -Suy --noconfirm --noprogressbar
}

install_virtualbox_guest(){
    # VirtualBox Guest Additions
    # https://wiki.archlinux.org/index.php/VirtualBox
    echo "[+] Deploy virtualbox guest"
    #/sbin/mv --force /etc/xdg/autostart/vboxclient.desktop /etc/xdg/autostart/vboxclient.desktop.old || true  # conflict with virtualbox-guest-utils
    /usr/bin/pacman -S --noconfirm --needed ${KERNEL} ${KERNEL}-headers virtualbox-guest-utils-nox virtualbox-guest-dkms nfs-utils
    /usr/bin/systemctl enable vboxservice.service
    /usr/bin/systemctl enable rpcbind.service

    if getent passwd ${USER_NAME} > /dev/null 2>&1; then
        # Add groups for VirtualBox folder sharing
        echo "[+] Adding support virtual box file system to user ${USER_NAME}"
        /usr/bin/groupadd ${USER_NAME}
        /usr/bin/usermod --append --groups "${USER_NAME},vboxsf" ${USER_NAME}
    fi
}

safe_reboot()
{
    echo '[+] Safe rebooting'
    nohup bash -c "sleep 1; shutdown -r now" < /dev/null > /dev/null 2>&1 &
}

main()
{
    prepare_env
    prepare_disk
    mount_filesystem
    install_base
    install_script
    make_bootable
    configure_system_chroot
    add_vagrant_user_chroot
    umount_filesystem
    safe_reboot
}

main_rsync()
{
    prepare_env
    prepare_disk
    mount_filesystem
    rsync_system
    install_script
    make_bootable
    add_vagrant_user
    configure_system_chroot
    umount_filesystem
    safe_reboot
}

# Check if the function exists (bash specific)
RUN_FUN=${1:-main}
if declare -f "${RUN_FUN}" > /dev/null
then
  # call arguments verbatim
  "$RUN_FUN"
else
  # Show a helpful error
  echo "'${RUN_FUN}' is not a known function name" >&2
  exit 1
fi
