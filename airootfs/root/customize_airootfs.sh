#!/bin/bash

cd /root
mkdir -p /home/root/Desktop
cd /home/root/Desktop
touch install.desktop
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
chmod +x -R /usr/bin /etc/lib /etc/X11 /home/root/Desktop /etc/install.sh
echo "live:live" | chpasswd
systemctl enable sddm
