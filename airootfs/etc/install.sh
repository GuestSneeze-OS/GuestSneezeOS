#!/bin/bash
read -p 'This script will erase all contents of /dev/sda (C:\). Type "yes" to proceed or "no" to cancel: ' response

if [[ "$response" == "yes" ]]; then
    echo "Erasing /dev/sda..."
    sudo dd if=/dev/zero of=/dev/sda bs=4M status=progress
    echo "Erased /dev/sda successfully."
    echo "GUESTSNEEZEOS INSTALLER | CREATING PARTITIONS"
    sudo gdisk /dev/sda <<EOF
n
+200M
ef00
n
8300
w
y
EOF

    echo "GUESTSNEEZEOS INSTALLER | FORMATTING PARTITIONS"
    sudo mkfs.fat -F32 /dev/sda1
    sudo mkfs.ext4 -O "^has_journal" /dev/sda2
    
    echo "GUESTSNEEZEOS INSTALLER | MOUNTING PARTITIONS"
    sudo mount /dev/sda2 /mnt
    sudo mkdir -p /mnt/boot/efi
    sudo mount /dev/sda1 /mnt/boot/efi

    echo "GUESTSNEEZEOS INSTALLER | INSTALLING BASE PACKAGES"
    sudo pacstrap /mnt base linux linux-firmware

    sudo genfstab -U /mnt >> /mnt/etc/fstab

    sudo arch-chroot /mnt <<EOF
echo en_US.UTF-8 UTF-8 >> /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 >> /etc/locale.conf
echo KEYMAP=us >> /etc/vconsole.conf
echo guestsneezeos >> /etc/hostname

cat <<HOSTS >> /etc/hosts
127.0.0.1        localhost
::1              localhost
127.0.1.1        guestsneezeos.localdomain guestsneezeos
HOSTS

echo "root:root" | chpasswd

pacman -S --noconfirm grub nano vim efibootmgr networkmanager network-manager-applet \
    mtools dosfstools git plasma xorg-server base-devel linux-headers bluez bluez-utils \
    cups xdg-utils steam xdg-user-dirs steam discord

mkinitcpio -P

grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --recheck
grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable org.cups.cupsd

useradd -mG wheel guestsneezeos
echo "guestsneezeos:guestsneezeos" | chpasswd

pacman -S --noconfirm wget
wget https://builds.garudalinux.org/repos/chaotic-aur/x86_64/yay-12.4.2-1-x86_64.pkg.tar.zst
pacman -U yay-12.4.2-1-x86_64.pkg.tar.zst

echo "guestsneezeos ALL=(ALL) ALL" >> /etc/sudoers

pacman --noconfirm -Sl multilib

yay -S --noconfirm plasma5-themes-vapor-steamos
EOF

    sudo umount -R /mnt

    echo "GuestSneezeOS has been installed successfully."

else
    echo "Operation canceled."
fi

