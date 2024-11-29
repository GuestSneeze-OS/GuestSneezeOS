#!/bin/bash

CONFIRMTOCONTINUE="NO"

EFI=$(whiptail --inputbox "Please enter an EFI partition (example /dev/sda1 or /dev/nvme0n1p1)" 8 39 Blue --title "GuestSneezeOS Installer" 3>&1 1>&2 2>&3)

SWAP=$(whiptail --inputbox "Please enter an Swap partition (example /dev/sda2)" 8 39 Blue --title "GuestSneezeOS Installer" 3>&1 1>&2 2>&3)

ROOT=$(whiptail --inputbox "Please enter your Root (/) partition (example /dev/sda3)" 8 39 Blue --title "GuestSneezeOS Installer" 3>&1 1>&2 2>&3)

USERNAME=$(whiptail --inputbox "Please enter your username" 8 39 Blue --title "GuestSneezeOS Installer" 3>&1 1>&2 2>&3)

PASSWORD=$(whiptail --passwordbox "Please enter your password" 8 39 Blue --title "GuestSneezeOS Installer" 3>&1 1>&2 2>&3)

DESKTOP=$(whiptail --title "GuestSneezeOS Installer" --menu "Select your installation type" 16 100 9\
        "1)" "GuestSneezeOS (Full SteamOS Experience)"
)

case $DESKTOP in 
    "1)")
        if whiptail --title "WARNING! - GuestSneezeOS Installer" --yesno "Due to graphical issues, this installation type will need an AMD graphics card. Using other cards like Intel or NVIDIA GPUs are not highly recommended as they have graphical issues when it comes into Gamescope sessions or Wayland sessions. Are you sure you want to install this installation type?" 8 78; then
            CONFIRMTOCONTINUE="YES"
        else
            CONFIRMTOCONTINUE="NO"
        ;;
esac

if [ "$CONFIRMTOCONTINUE" = "YES" ]; then

mkfs.vfat -F32 -n "EFISYSTEM" "${EFI}"
mkswap "${SWAP}"
swapon "${SWAP}"
mkfs.ext4 -L "ROOT" "${ROOT}"
mount -t ext4 "${ROOT}" /mnt
mkdir /mnt/boot
mount -t vfat "${EFI}" /mnt/boot/
pacstrap /mnt base base-devel --noconfirm --needed
pacstrap /mnt linux linux-firmware --noconfirm --needed
pacstrap /mnt networkmanager network-manager-applet wireless_tools nano intel-ucode bluez bluez-utils blueman git --noconfirm --needed
genfstab -U /mnt >> /mnt/etc/fstab
bootctl install --path /mnt/boot
echo "default arch.conf" >> /mnt/boot/loader/loader.conf
cat <<EOF > /mnt/boot/loader/entries/arch.conf
title GuestSneezeOS
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=${ROOT} rw
EOF


cat <<REALEND > /mnt/next.sh
useradd -m $USER
usermod -aG wheel,storage,power,audio $USER
echo $USER:$PASSWORD | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

ln -sf /usr/share/zoneinfo/Asia/Dubai /etc/localtime
hwclock --systohc

echo "guestsneezeos" > /etc/hostname
cat <<EOF > /etc/hosts
127.0.0.1	localhost
::1			localhost
127.0.1.1	guestsneezeos.localdomain	guestsneezeos
EOF

pacman -S xorg wayland pulseaudio --noconfirm --needed

systemctl enable NetworkManager bluetooth

if [[ $DESKTOP == '1' ]]
then
    pacman -S gamescope steam plasma-shell kde-apps sddm --noconfirm --needed
    systemctl enable sddm
fi
REALEND


arch-chroot /mnt sh next.sh
else
DESKTOP=$(whiptail --title "GuestSneezeOS Installer" --menu "Select your installation type" 16 100 9\
        "1)" "GuestSneezeOS (Full SteamOS experience)"
)
fi
