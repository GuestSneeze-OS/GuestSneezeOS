#!/bin/bash
echo -n "Enter username: "
read username
echo -n "Enter root password: "
read -s password
echo -n "Enter gpu type [intel, amd, or nvidia]: "
read gpu
echo $password | sudo -S pacman -Syyuu --noconfirm
echo $password | sudo -S pacman -S --noconfirm wget dos2unix sed
wget -O /home/$username/.bashrc https://raw.githubusercontent.com/GuestSneeze-OS/GuestSneezeOS/refs/heads/main/airootfs/etc/skel/.bashrc
echo $password | sudo -S pacman -S --noconfirm --needed grub-customizer htop btop nemo neofetch xorg cpupower firefox libreoffice base-devel git vim cronie net-tools plasma kde-applications obs-studio
echo $password | sudo -S systemctl enable cronie sddm avahi-daemon
echo $password | sudo -S systemctl enable cpupower
echo $password | sudo -S systemctl start cpupower
if [ "$gpu" == "amd" ]; then
    echo $password | sudo -S pacman -S --needed --noconfirm vulkan-radeon amdvlk mesa
elif [ "$gpu" == "nvidia" ]; then
    echo $password | sudo -S pacman -S --needed --noconfirm nvidia-dkms nvidia-utils mesa
else
    echo $password | sudo -S pacman -S --needed --noconfirm mesa xf86-video-intel vulkan-intel
fi
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
cd ..
yay -S discord dxvk-bin mangohud goverlay ttf-ms-win11-auto --noconfirm
cd /home/$username/
wget https://raw.githubusercontent.com/GuestSneeze-OS/GuestSneezeOS/refs/heads/main/pacman.conf
echo $password | sudo -S cp /home/$username/pacman.conf /etc/pacman.conf
rm -rf /home/$username/pacman.conf
# Hope - Mohamed (GuestSneezeOSDev)
pacman -S steam

echo 'Installation Completed.' 
exit 1
