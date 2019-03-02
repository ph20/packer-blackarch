#!/usr/bin/env bash
localectl set-keymap --no-convert us  # set keymap to use
# update pacman package database
echo "[+] Updating pacman database"
pacman -Syy --noconfirm --quiet --noprogressbar > /dev/null
pacman -S --noconfirm  --quiet --noprogressbar --needed pacman-contrib gptfdisk patch > /dev/null