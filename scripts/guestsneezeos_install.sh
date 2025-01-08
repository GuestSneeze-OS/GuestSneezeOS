#!/bin/bash
# Yep, this script is inspired by winesapOS. Check it out!
# https://github.com/winesapOS/winesapOS
. ./env/default_env.sh

#if [ -f /etc/os-release ]; then
#        . /etc/os-release
#        if [[ "$ID" == "arch" || "$ID_LIKE" == *"arch"* ]]; then
#            echo "This system is running Arch Linux or an Arch-based distribution."
#            return 0
#        else
#           echo "Not running an Arch-based distro... exiting"
#fi

clear_cache() {
    chroot "${GUESTSNEEZEOS_WORKDIR}" pacman --noconfirm -S -c -c
    # Each directory gets deleted separately in case the directory does not exist yet.
    # Otherwise, the entire 'rm' command will not run if one of the directories is not found.
    rm -rf "${WINESAPOS_INSTALL_DIR}"/var/cache/pacman/pkg/*
    rm -rf "${WINESAPOS_INSTALL_DIR}"/home/"${WINESAPOS_USER_NAME}"/.cache/go-build/*
    rm -rf "${WINESAPOS_INSTALL_DIR}"/home/"${WINESAPOS_USER_NAME}"/.cache/paru/*
    rm -rf "${WINESAPOS_INSTALL_DIR}"/home/"${WINESAPOS_USER_NAME}"/.cache/yay/*
    rm -rf "${WINESAPOS_INSTALL_DIR}"/home/"${WINESAPOS_USER_NAME}"/.cargo/*
    rm -rf "${WINESAPOS_INSTALL_DIR}"/tmp/*
}

pacman_install_chroot() {
    chroot "${WINESAPOS_INSTALL_DIR}" /usr/bin/pacman --noconfirm -S --needed "$@"
    clear_cache
}

aur_install_chroot() {
    chroot "${WINESAPOS_INSTALL_DIR}" sudo -u "${WINESAPOS_USER_NAME}" yay --noconfirm -S --removemake "$@"
    clear_cache
}