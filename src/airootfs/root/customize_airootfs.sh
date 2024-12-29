#!/bin/bash

cd /root
mkdir -p /home/live/Desktop
cd /home/live/Desktop
echo '[Desktop Entry]
Comment[en_US]=
Comment=
Exec=/etc/install.sh
GenericName[en_US]=
GenericName=
Icon=run-install
MimeType=
Name[en_US]=Install SteamOS on this PC
Name=Installs GuestSneezeOS on this PC 
Path=
StartupNotify=true
Terminal=false
TerminalOptions=
Type=Application
X-DBUS-ServiceName=
X-DBUS-StartupType=
X-KDE-SubstituteUID=false
X-KDE-Username=' >> install.desktop
cd /root
cd -
chmod +x -R /usr/bin /etc/X11 /home/root/Desktop /etc/install.sh
chmod a+x /etc/install.sh
echo "live:live" | chpasswd
# INSTALL YAY - GuestSneezeOSDev
wget https://builds.garudalinux.org/repos/chaotic-aur/x86_64/yay-12.4.2-1.1-x86_64.pkg.tar.zst
sudo pacman -U yay-12.4.2-1.1-x86_64.pkg.tar.zst
rm -rf yay-12.4.2-1.1-x86_64.pkg.tar.zst
systemctl enable sddm
