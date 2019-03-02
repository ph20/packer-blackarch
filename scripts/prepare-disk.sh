#!/usr/bin/env bash
set -e
set -x

if [ -e /dev/vda ]; then
  DEVICE=/dev/vda
elif [ -e /dev/sda ]; then
  DEVICE=/dev/sda
else
  echo "ERROR: There is no disk available for installation" >&2
  exit 1
fi

ROOT_PART="${DEVICE}1"

echo "[+] Start preparrin disk ${DEVICE}"
# make and format partitions
echo "[+] Clearing partition table on ${DEVICE}"
/usr/bin/sgdisk --zap ${DEVICE}
echo "[+] Destroying magic strings and signatures on ${DEVICE}"
/usr/bin/dd if=/dev/zero of=${DEVICE} bs=512 count=2048
/usr/bin/wipefs --all ${DEVICE}
echo "[+] Creating /root partition on ${DEVICE}"
/usr/bin/sgdisk --new=1:0:0 ${DEVICE}
echo "[+] Setting ${DEVICE} bootable"
/usr/bin/sgdisk ${DEVICE} --attributes=1:set:2
echo '[+] Creating /root filesystem (ext4)'
/usr/bin/mkfs.ext4 -O ^64bit -F -m 0 -q -L root ${ROOT_PART}