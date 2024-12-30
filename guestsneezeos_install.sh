#!/bin/bash
# Yep, this script is inspired and uses some code from winesapOS. Check it out! 
# https://github.com/winesapOS/winesapOS

# Load default environment variables.
../env/gsos_default.sh
# Edit the OS-RELEASE-GUESTSNEEZEOS file.


if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Please use sudo." 1>&2
   exit 1
fi

if [[ "${GUESTSNEEZEOS_DE}" == "plasma" ]]; then
   echo "Installing the KDE Plasma desktop environment..."
   echo "plasma-meta" >> "src/packages.x86_64"
   echo "plasma-nm" >> "src/packages.x86_64"
   # The KDE Plasma theme is by @LukeShortCloud, go follow him!
   cd ../ # Move to parent directory
   wget https://steamdeck-packages.steamos.cloud/archlinux-mirror/jupiter-rel/os/x86_64/steamdeck-kde-presets-0.16-1-any.pkg.tar.zst
   zstd -d steamdeck-kde-presets-0.16-1-any.pkg.tar.zst
   mv steamdeck-kde-presets-0.16-1-any.pkg.tar/ GuestSneezeOS/
   cd GuestSneezeOS/
   cd steamdeck-kde-presets-0.16-1-any.pkg.tar/
   mv etc/ ../airootfs/
   mv usr/ ../airootfs/
   cd ../
   rm -rf steamdeck-kde-presets-0.16-1-any.pkg.tar/
   #Install SDDM
   echo "sddm" >> "src/packages.x86_64"
   echo "systemctl enable sddm" >> "src/airootfs/root/customize_airootfs.sh"
   echo "Installing the KDE Plasma desktop environment... Completed!"
   
elif [[ "${GUESTSNEEZEOS_DE}" == "hyprland" ]]; then
   echo "Installing the Hyprland desktop enviorment..."
   #Install SDDM
   echo "sddm" >> "src/packages.x86_64"
   echo "systemctl enable sddm" >> "src/airootfs/root/customize_airootfs.sh"
   echo "hyprland-meta" >> "src/packages.x86_64"
   echo "waybar" >> "src/packages.x86_64"
   # TODO: Install Theme
   echo "Installing the Hyprland desktop enviorment complete."

elif [[ "${GUESTSNEEZEOS_DE}" == "gnome" ]]; then
   echo "Installing the Gnome desktop enviorment..."
   echo "gdm
   gnome-shell
   gnome-session
   gnome-console
   mesa
   gnome-control-center
   gnome-settings-daemon
   nautilus" >> "src/packages.x86_64"
   echo "systemctl enable gdm" >> "src/airootfs/root/customize_airootfs.sh"
   echo "Installing the Gnome desktop enviorment complete."
fi

if [[ "${GUESTSNEEZEOS_GAMING}" == "true" ]]; then
   echo "steam" >> "src/packages.x86_64"
   echo "xorg-xrandr" >> "src/packages.x86_64"
   echo "lutris" >> "src/packages.x86_64"
   echo "gamescope" >> "src/packages.x86_64"
fi

if [[ "${GUESTSNEEZEOS_XORG}" == "true" ]]; then
   echo "xorg" >> "src/packages.x86_64"
   echo "xdg-user-dirs" >> "src/packages.x86_64"
fi

if [[ "${GUESTSNEEZEOS_WIFI}" == "true" ]]; then
   echo "networkmanager" >> "src/packages.x86_64"
   echo "network-manager-applet" >> "src/packages.x86_64"
fi

if [[ "${GUESTSNEEZEOS_ENABLE_PORTABLE_STORAGE}" == "true" ]]; then
   echo "TODO"
fi

if [[ "${GUESTSNEEZEOS_BUILD}" == "true" ]]; then
   # Finally, build
   src/archiso/archiso/mkarchiso -v -w ${GUESTSNEEZEOS_WORKDIR} -o ${GUESTSNEEZEOS_OUTDIR} src/ 
   echo "Build Complete"
fi

if [[ "${GUESTSNEEZEOS_CLEAN_BUILD}" == "true" ]]; then
   rm -rf ${GUESTSNEEZEOS_WORKDIR}
   echo "Cleaned the project (DELETED ${GUESTSNEEZEOS_WORKDIR})"
fi
