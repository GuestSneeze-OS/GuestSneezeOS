#!/bin/bash

guestsneezeos_distro_detected=$(grep -P '^ID=' /etc/os-release | cut -d= -f2)
export \
  GUESTSNEEZEOS_IMAGE_TYPE="${GUESTSNEEZEOS_IMAGE_TYPE:-performance}" \
  GUESTSNEEZEOS_WORKDIR="${GUESTSNEEZEOS_WORKDIR:-/work}" \
  GUESTSNEEZEOS_DISTRO="${GUESTSNEEZEOS_DISTRO:-arch}" \
  GUESTSNEEZEOS_DISTRO_DETECTED="${guestsneezeos_distro_detected}" \
  GUESTSNEEZEOS_ENABLE_TESTING_REPO="${GUESTSNEEZEOS_ENABLE_TESTING_REPO:-false}" \
  GUESTSNEEZEOS_DE="${GUESTSNEEZEOS_DE:-plasma}" \
  GUESTSNEEZEOS_ENCRYPT="${GUESTSNEEZEOS_ENCRYPT:-false}" \
  GUESTSNEEZEOS_ENCRYPT_PASSWORD="${GUESTSNEEZEOS_ENCRYPT_PASSWORD:-password}" \
  GUESTSNEEZEOS_LOCALE="${GUESTSNEEZEOS_LOCALE:-en_US.UTF-8 UTF-8}" \
  GUESTSNEEZEOS_CPU_MITIGATIONS="${GUESTSNEEZEOS_CPU_MITIGATIONS:-false}" \
  GUESTSNEEZEOS_DISABLE_KERNEL_UPDATES="${GUESTSNEEZEOS_DISABLE_KERNEL_UPDATES:-false}" \
  GUESTSNEEZEOS_APPARMOR="${GUESTSNEEZEOS_APPARMOR:-false}" \
  GUESTSNEEZEOS_SUDO_NO_PASSWORD="${GUESTSNEEZEOS_SUDO_NO_PASSWORD:-true}" \
  GUESTSNEEZEOS_DISABLE_KWALLET="${GUESTSNEEZEOS_DISABLE_KWALLET:-true}" \
  GUESTSNEEZEOS_ENABLE_KLIPPER="${GUESTSNEEZEOS_ENABLE_KLIPPER:-true}" \
  GUESTSNEEZEOS_INSTALL_GAMING_TOOLS="${GUESTSNEEZEOS_INSTALL_GAMING_TOOLS:-true}" \
  GUESTSNEEZEOS_INSTALL_PRODUCTIVITY_TOOLS="${GUESTSNEEZEOS_INSTALL_PRODUCTIVITY_TOOLS:-true}" \
  GUESTSNEEZEOS_DEVICE="${GUESTSNEEZEOS_DEVICE:-vda}" \
  GUESTSNEEZEOS_PARTITION_TABLE="${GUESTSNEEZEOS_PARTITION_TABLE:-gpt}" \
  GUESTSNEEZEOS_ENABLE_PORTABLE_STORAGE="${GUESTSNEEZEOS_ENABLE_PORTABLE_STORAGE:-true}" \
  GUESTSNEEZEOS_BUILD_IN_VM_ONLY="${GUESTSNEEZEOS_BUILD_IN_VM_ONLY:-true}" \
  GUESTSNEEZEOS_BUILD_CHROOT_ONLY="${GUESTSNEEZEOS_BUILD_CHROOT_ONLY:-false}" \
  GUESTSNEEZEOS_USER_NAME="${GUESTSNEEZEOS_USER_NAME:-winesap}" \
  GUESTSNEEZEOS_XORG_ENABLE="${GUESTSNEEZEOS_XORG_ENABLE:-true}" \
  GUESTSNEEZEOS_SINGLE_MIRROR="${GUESTSNEEZEOS_SINGLE_MIRROR:-false}" \
  GUESTSNEEZEOS_SINGLE_MIRROR_URL="${GUESTSNEEZEOS_SINGLE_MIRROR_URL:-http://ohioix.mm.fcix.net/archlinux}" \
  GUESTSNEEZEOS_BOOTLOADER="${GUESTSNEEZEOS_BOOTLOADER:-grub}" \
  CMD_PACMAN_INSTALL=(/usr/bin/pacman --noconfirm -S --needed) \
  CMD_AUR_INSTALL=(sudo -u winesap yay --noconfirm -S --removemake) \
  GUESTSNEEZEOS_OUTPUT="${GUESTSNEEZEOS_OUTPUT:-output}"
  CMD_FLATPAK_INSTALL=(flatpak install -y --noninteractive)
export \
  DEVICE="/dev/${GUESTSNEEZEOS_DEVICE}"