#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

read -p "Enter the drive to erase (e.g., /dev/sda dont write the /dev/ part tho): " DRIVE
if [[ ! -b $DRIVE ]]; then
    echo "Error: $DRIVE does not exist or is not a valid block device."
    exit 1
fi

dd if=/dev/zero of=/dev/$DRIVE bs=1M status=progress

gdisk /dev/$DRIVE <<EOF
n
1
2048
+200M
ef00
n
2


8300
w
y
EOF

mkfs.fat -F32 /dev/${DRIVE}1
mkfs.ext4 /dev/${DRIVE}2 

mount /dev/${DRIVE}2 /mnt
mkdir -p /mnt/boot/efi
mount /dev/${DRIVE}1 /mnt/boot/efi
pacstrap /mnt wget base linux linux-firmware nano vim vi --noconfirm

genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt <<EOF
file /etc/locale.conf
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
file /etc/vconsole.conf
echo "KEYMAP=us" >> /etc/vconsole.conf
cd /etc && wget https://raw.githubusercontent.com/GuestSneeze-OS/GuestSneezeOS/refs/heads/main/airootfs/etc/hostname
cd /
file /etc/hosts
echo "127.0.0.1	localhost
::1		localhost
127.0.1.1	guestsneezeos.localdomain	guestsneezeos" >> /etc/hosts
pacman -S htop btop nemo neofetch xorg cpupower firefox libreoffice base-devel git vim cronie net-tools plasma kde-applications grub efibootmgr networkmanager network-manager-applet mtools dosfstools git wget base-devel linux-headers bluez bluez-utils cups xdg-utils xdg-user-dirs --needed --noconfirm
pacman -S mesa xf86-video-intel vulkan-intel --needed --noconfirm
pacman -S --needed --noconfirm vulkan-radeon amdvlk mesa
# grr nvidia fix your drivers
#pacman -S --needed --noconfirm nvidia-dkms nvidia-utils mesa


mkinitcpio -p linux
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --recheck && grub-mkconfig -o/boot/grub.cfg
systemctl enable NetworkManager && systemctl enable bluetooth && systemctl enable org.cups.cupsd
systemctl enable cronie sddm avahi-daemon
useradd -mG wheel gamer
passwd gamer
gamer
gamer
exit 
EOF

umount -a
echo 'Installation Completed Please Reboot'
