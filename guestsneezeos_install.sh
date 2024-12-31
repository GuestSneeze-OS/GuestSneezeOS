#!/bin/bash
# Yep, this script is inspired by winesapOS. Check it out!
# https://github.com/winesapOS/winesapOS
export \
  GUESTSNEEZEOS_ENABLE_PORTABLE_STORAGE="${GUESTSNEEZEOS_ENABLE_PORTABLE_STORAGE:-true}" \
  GUESTSNEEZEOSOS_DE="${GUESTSNEEZEOS_DE:-plasma}" \
  GUESTSNEEZEOS_GAMING="${GUESTSNEEZEOS_GAMING:-true}" \
  GUESTSNEEZEOS_XORG="${GUESTSNEEZEOS_XORG:-true}" \
  GUESTSNEEZEOS_WIFI="${GUESTSNEEZEOS_WIFI:-true}" \
  GUESTSNEEZEOS_OUTDIR="${GUESTSNEEZEOS_OUTDIR:-bin/}" \
  GUESTSNEEZEOS_WORKDIR="${GUESTSNEEZEOS_WORKDIR:-work/}" \
  GUESTSNEEZEOS_DEVICE="${GUESTSNEEZEOS_DEVICE:-vda}" \
  GUESTSNEEZEOS_LOCALE="${GUESTSNEEZEOS_LOCALE:-en_US.UTF-8 UTF-8}" \
  GUESTSNEEZEOS_USERNAME="${GUESTSNEEZEOS_USERNAME:-guestsneezeos}" \
  DEVICE="/dev/${GUESTSNEEZEOS_DEVICE}"
#GUESTSNEEZEOS_BUILD_ARCHISO="${GUESTSNEEZEOS_BUILD_ARCHISO:-false}" \

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Please use sudo." 1>&2
   exit 1
fi

if [[ "${GUESTSNEEZEOS_BUILD_ARCHISO}" == "true" ]]; then
   echo "Archiso build will be deprecated in the near future"
   if [[ "${GUESTSNEEZEOS_DE}" == "plasma" ]]; then
   echo "Installing the KDE Plasma desktop environment..."
   echo "plasma-meta" >> "src_archiso/packages.x86_64"
   echo "plasma-nm" >> "src_archiso/packages.x86_64"
   # The KDE Plasma theme is by @LukeShortCloud, go follow him!
   cd ../ # Move to parent directory
   wget https://steamdeck-packages.steamos.cloud/archlinux-mirror/jupiter-rel/os/x86_64/steamdeck-kde-presets-0.16-1-any.pkg.tar.zst
   zstd -d steamdeck-kde-presets-0.16-1-any.pkg.tar.zst
   mv steamdeck-kde-presets-0.16-1-any.pkg.tar/ GuestSneezeOS/
   cd GuestSneezeOS/
   cd steamdeck-kde-presets-0.16-1-any.pkg.tar/
   mv etc/ ../src_archiso/airootfs/
   mv usr/ ../src_archiso/airootfs/
   cd ../
   rm -rf steamdeck-kde-presets-0.16-1-any.pkg.tar/
   #Install SDDM
   echo "sddm" >> "src_archiso/packages.x86_64"
   echo "systemctl enable sddm" >> "src_archiso/airootfs/root/customize_airootfs.sh"
   echo "Installing the KDE Plasma desktop environment... Completed!"
   
   elif [[ "${GUESTSNEEZEOS_DE}" == "hyprland" ]]; then
      echo "Installing the Hyprland desktop enviorment..."
      #Install SDDM
      echo "sddm" >> "src_archiso/packages.x86_64"
      echo "systemctl enable sddm" >> "src_archiso/airootfs/root/customize_airootfs.sh"
      echo "hyprland-meta" >> "src_archiso/packages.x86_64"
      echo "waybar" >> "src_archiso/packages.x86_64"
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
   nautilus" >> "src_archiso/packages.x86_64"
   echo "systemctl enable gdm" >> "src_archiso/airootfs/root/customize_airootfs.sh"
      echo "Installing the Gnome desktop enviorment complete."
   fi

   if [[ "${GUESTSNEEZEOS_GAMING}" == "true" ]]; then
      echo "	" >> "src_archiso/packages.x86_64"
      echo "steam" >> "src_archiso/packages.x86_64"
      echo "xorg-xrandr" >> "src_archiso/packages.x86_64"
      echo "lutris" >> "src_archiso/packages.x86_64"
      echo "gamescope" >> "src_archiso/packages.x86_64"
   fi

   if [[ "${GUESTSNEEZEOS_XORG}" == "true" ]]; then
      echo "xorg" >> "src_archiso/packages.x86_64"
      echo "xdg-user-dirs" >> "src_archiso/packages.x86_64"
   fi

   if [[ "${GUESTSNEEZEOS_WIFI}" == "true" ]]; then
      echo "networkmanager" >> "src_archiso/packages.x86_64"
      echo "network-manager-applet" >> "src_archiso/packages.x86_64"
   fi
   src_archiso/archiso/archiso/mkarchiso -v -w ${GUESTSNEEZEOS_WORKDIR} -o ${GUESTSNEEZEOS_OUTDIR} src_archiso/ 
   echo "Build Complete"
   rm -rf ${GUESTSNEEZEOS_WORKDIR}
   echo "Cleaned the project (DELETED ${GUESTSNEEZEOS_WORKDIR})"
fi

# The code here is from winesapOS!, check it out!
# https://github.com/winesapOS/winesapOS
if [[ "${GUESTSNEEZEOS_ENABLE_PORTABLE_STORAGE}" == "true" ]]; then
   pacman_install_chroot() {
    chroot "${GUESTSNEEZEOS_WORKDIR}" /usr/bin/pacman --noconfirm -S --needed "$@"
   }

   if [[ "${GUESTSNEEZEOS_CREATE_DEVICE}" == "true" ]]; then

    mkdir ../${GUESTSNEEZEOS_OUTDIR}

    if [[ -n "${GUESTSNEEZEOS_CREATE_DEVICE_SIZE}" ]]; then
            fallocate -l "${GUESTSNEEZEOS_CREATE_DEVICE_SIZE}GiB" ../${GUESTSNEEZEOS_OUTDIR}guestsneezeos.img
    else
        if [[ "${GUESTSNEEZEOS_ENABLE_PORTABLE_STORAGE}" == "true" ]]; then
            fallocate -l 25GiB ../${GUESTSNEEZEOS_OUTDIR}guestsneezeos.img
        else
            fallocate -l 8GiB ../${GUESTSNEEZEOS_OUTDIR}guestsneezeos.img
        fi
    fi

   DEVICE="$(losetup --partscan --find --show ../${GUESTSNEEZEOS_OUTDIR}guestsneezeos.img)"
   echo "${DEVICE}" | tee /tmp/guestsneezeos-device.txt
   parted "${DEVICE}" mkpart primary 2MiB 16GiB
   parted "${DEVICE}" set 2 msftdata on
   parted "${DEVICE}" mkpart primary fat32 16GiB 16.5GiB
   parted "${DEVICE}" set 3 esp on
   parted "${DEVICE}" mkpart primary ext4 16.5GiB 17.5GiB
   parted "${DEVICE}" set 4 boot on
   parted "${DEVICE}" mkpart primary btrfs 17.5GiB 100%
   mkfs -t exfat "${DEVICE_WITH_PARTITION}2"
   exfatlabel "${DEVICE_WITH_PARTITION}2" gsos-drive
   mkfs -t vfat "${DEVICE_WITH_PARTITION}3"
   fatlabel "${DEVICE_WITH_PARTITION}3" GSOS-EFI
   mkfs -t ext4 "${DEVICE_WITH_PARTITION}4"
   e2label "${DEVICE_WITH_PARTITION}4" guestsneezeos-boot
   root_partition="${DEVICE_WITH_PARTITION}5"
   mkfs -t btrfs "${root_partition}"
   btrfs filesystem label "${root_partition}" guestsneezeos-root
   echo "Creating partitions complete."
   mount -t btrfs -o subvol=/,compress-force=zstd:1,discard,noatime,nodiratime "${root_partition}" "${GUESTSNEEZEOS_WORKDIR}"
   btrfs subvolume create "${GUESTSNEEZEOS_WORKDIR}/home"
   mount -t btrfs -o subvol=/home,compress-force=zstd:1,discard,noatime,nodiratime "${root_partition}" "${GUESTSNEEZEOS_WORKDIR}/home"
   btrfs subvolume create "${GUESTSNEEZEOS_WORKDIR}/swap"
   mount -t btrfs -o subvol=/swap,compress-force=zstd:1,discard,noatime,nodiratime "${root_partition}" "${GUESTSNEEZEOS_WORKDIR}/swap"
   mkdir "${GUESTSNEEZEOS_WORKDIR}/boot"
   mount -t ext4 "${DEVICE_WITH_PARTITION}4" "${GUESTSNEEZEOS_WORKDIR}/boot"
   mkdir "${GUESTSNEEZEOS_WORKDIR}"/boot/efi
   export efi_partition=""
   export efi_partition="${DEVICE_WITH_PARTITION}3"
   mount -t vfat "${efi_partition}" "${GUESTSNEEZEOS_WORKDIR}/boot/efi"
   for i in tmp var/log var/tmp; do
        mkdir -p "${GUESTSNEEZEOS_WORKDIR}"/${i}
        mount tmpfs -t tmpfs -o nodev,nosuid "${GUESTSNEEZEOS_WORKDIR}/${i}"
    done
   echo "Mounting partitions complete."
   pacman -S -y --noconfirm
   echo "Setting up fastest pacman mirror on live media complete."
   echo "Creating the keyrings used by Pacman..."
   killall gpg-agent
   umount -l /etc/pacman.d/gnupg
   rm -r -f /etc/pacman.d/gnupg
   pacman-key --init
   # The section after this installs winesapOS repositories into the pacman.conf, which is not required because this is to port winesapOS's portability support
   # to GuestSneezeOS.
   pacstrap -i "${GUESTSNEEZEOS_WORKDIR}" base base-devel curl libeatmydata fwupd --noconfirm
   chroot "${GUESTSNEEZEOS_WORKDIR}" pacman -S -y -y
   pacman_install_chroot efibootmgr iwd mkinitcpio modem-manager-gui networkmanager usb_modeswitch zram-generator
   chroot "${GUESTSNEEZEOS_WORKDIR}" systemctl enable fstrim.timer NetworkManager systemd-timesyncd
   echo "label  ::1/128       0
label  ::/0          1
label  2002::/16     2
label ::/96          3
label ::ffff:0:0/96  4
precedence  ::1/128       50
precedence  ::/0          40
precedence  2002::/16     30
precedence ::/96          20
precedence ::ffff:0:0/96  100" > "${GUESTSNEEZEOS_WORKDIR}"/etc/gai.conf
   sed -i 's/MODULES=(/MODULES=(btrfs\ usbhid\ xhci_hcd\ nvme\ vmd\ /g' "${GUESTSNEEZEOS_WORKDIR}"/etc/mkinitcpio.conf
   chroot "${GUESTSNEEZEOS_WORKDIR}" locale-gen
   echo "LANG=$(echo "${GUESTSNEEZEOS_LOCALE}" | cut -d' ' -f1)" > "${GUESTSNEEZEOS_WORKDIR}"/etc/locale.conf
   echo steamos > "${GUESTSNEEZEOS_WORKDIR}"/etc/hostname
   # According to @LukeShortCloud in his script (winesapos_install.sh L371), it isnt a typo
   echo "127.0.1.1    steamos" >> "${GUESTSNEEZEOS_WORKDIR}"/etc/hosts
   pacman_install_chroot inetutils fprintd
        echo "LABEL=guestsneezeos-root        	/         	btrfs     	rw,noatime,nodiratime,compress-force=zstd:1,discard,space_cache=v2,subvolid=$(btrfs subvolume show /work | grep "Subvolume ID"  | awk '{print $3}'),subvol=/	0 0
LABEL=guestsneezeos-root        	/home     	btrfs     	rw,noatime,nodiratime,compress-force=zstd:1,discard,space_cache=v2,subvolid=$(btrfs subvolume show /work/home | grep "Subvolume ID"  | awk '{print $3}'),subvol=/home	0 0
LABEL=guestsneezeos-root        	/swap     	btrfs     	rw,noatime,nodiratime,compress-force=zstd:1,discard,space_cache=v2,subvolid=$(btrfs subvolume show /work/swap | grep "Subvolume ID"  | awk '{print $3}'),subvol=/swap	0 0
LABEL=guestsneezeos-boot        	/boot     	ext4      	rw,relatime	0 2
LABEL=GSOS-EFI        	/boot/efi 	vfat      	rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=iso8859-1,shortname=mixed,errors=remount-ro	0 2" > "${GUESTSNEEZEOS_wORKDIR}"/etc/fstab
    echo "tmpfs    /tmp    tmpfs    rw,nosuid,nodev,inode64    0 0
tmpfs    /var/log    tmpfs    rw,nosuid,nodev,inode64    0 0
tmpfs    /var/tmp    tmpfs    rw,nosuid,nodev,inode64    0 0" >> "${GUESTSNEEZEOS_WORKDIR}"/etc/fstab
   echo "tmpfs    /tmp    tmpfs    rw,nosuid,nodev,inode64    0 0
tmpfs    /var/log    tmpfs    rw,nosuid,nodev,inode64    0 0
tmpfs    /var/tmp    tmpfs    rw,nosuid,nodev,inode64    0 0" >> "${WINESAPOS_WORKDIR}"/etc/fstab
    echo "View final /etc/fstab file:"
    cat "${GUESTSNEEZEOS_WORKDIR}"/etc/fstab
    echo "Saving partition mounts to /etc/fstab complete."
    pacman_install_chroot binutils cmake dkms fakeroot gcc git make
    echo 'MAKEFLAGS="-j $(nproc)"' >> "${GUESTSNEEZEOS_WORKDIR}"/etc/makepkg.conf
    pacman_install_chroot \
  mesa \
  libva-mesa-driver \
  mesa-vdpau \
  opencl-rusticl-mesa \
  vulkan-intel \
  vulkan-mesa-layers \
  vulkan-nouveau \
  vulkan-radeon \
  vulkan-swrast \
  lib32-mesa \
  lib32-libva-mesa-driver \
  lib32-mesa-vdpau \
  lib32-vulkan-nouveau \
  lib32-opencl-rusticl-mesa \
  lib32-vulkan-intel \
  lib32-vulkan-mesa-layers \
  lib32-vulkan-radeon \
  lib32-vulkan-swrast

echo "
options radeon si_support=0
options radeon cik_support=0
options amdgpu si_support=1
options amdgpu cik_support=1" >> "${GUESTSNEEZEOS_WORKDIR}"/usr/lib/modprobe.d/guestsneezeos-amd.conf
echo "
options amdgpu noretry=0" >> "${GUESTSNEEZEOS_WORKDIR}"/usr/lib/modprobe.d/guestsneezeos-amd.conf
pacman_install_chroot flatpak
echo -e "root\nroot" | chroot "${GUESTSNEEZEOS_WORKDIR}" passwd root
chroot "${GUESTSNEEZEOS_WORKDIR}" useradd --create-home guestsneezeos
echo -e "${WINESAPOS_USER_NAME}\n${GUESTSNEEZEOS_USERNAME} | chroot "${GUESTSNEEZEOS_WORKDIR}" passwd "${GUESTSNEEZEOS_USERNAME}"
echo "${GUESTSNEEZEOS_USERNAME} ALL=(root) NOPASSWD:ALL" > "${GUESTSNEEZEOS_WORKDIR}"/etc/sudoers.d/"${GUESTSNEEZEOS_USERNAME}"
chmod 0440 "${WINESAPOS_INSTALL_DIR}"/etc/sudoers.d/"${WINESAPOS_USER_NAME}"
mkdir "${GUESTSNEEZEOS_WORKDIR}"/home/"${GUESTSNEEZEOS_USERNAME}"/Desktop
chroot "${GUESTSNEEZEOS_WORKDIR}" ln -s /home/"${GUESTSNEEZEOS_USERNAME}" /home/deck
echo "Configuring user accounts complete."
mkdir -p "${GUESTSNEEZEOS_WORKDIR}"/var/lib/guestsneezeos/
chroot "${GUESTSNEEZEOS_WORKDIR}" pacman -S -w --noconfirm broadcom-wl-dkms
for i in $(ls -1 "${GUESTSNEEZEOS_WORKDIR}"/var/cache/pacman/pkg/ | grep broadcom-wl-dkms)
    do cp "${GUESTSNEEZEOS_WORKDIR}"/var/cache/pacman/pkg/"${i}" "${GUESTSNEEZEOS_WORKDIR}"/var/lib/guestsneezeos/
done
pacman_install_chroot libpipewire lib32-libpipewire wireplumber
pacman_install_chroot firefox
aur_install_chroot() {
    chroot "${GUESTSNEEZEOS_WORKDIR}" sudo -u "${GUESTSNEEZEOS_USERNAME}" yay --noconfirm -S --removemake "$@"
}
echo "Installing additional file system support..."
echo "APFS"
aur_install_chroot apfsprogs-git linux-apfs-rw-dkms-git
echo "Bcachefs"
pacman_install_chroot bcachefs-tools
echo "Btrfs"
pacman_install_chroot btrfs-progs
echo "CephFS"
aur_install_chroot ceph-libs-bin ceph-bin
echo "CIFS/SMB"
pacman_install_chroot cifs-utils
echo "eCryptFS"
pacman_install_chroot ecryptfs-utils
echo "EROFS"
pacman_install_chroot erofs-utils
echo "ext3 and ext4"
pacman_install_chroot e2fsprogs lib32-e2fsprogs
echo "exFAT"
pacman_install_chroot exfatprogs
echo "F2FS"
pacman_install_chroot f2fs-tools
echo "FAT12, FAT16, and FAT32"
pacman_install_chroot dosfstools mtools
echo "FATX16 and FATX32"
aur_install_chroot fatx
echo "GFS2"
aur_install_chroot gfs2-utils
echo "GlusterFS"
pacman_install_chroot glusterfs
echo "HFS and HFS+"
aur_install_chroot hfsprogs
echo "JFS"
pacman_install_chroot jfsutils
echo "MinIO"
pacman_install_chroot minio
echo "NFS"
pacman_install_chroot nfs-utils
echo "NILFS2"
pacman_install_chroot nilfs-utils
echo "NTFS"
pacman_install_chroot ntfs-3g
echo "ReiserFS"
pacman_install_chroot reiserfsprogs
aur_install_chroot reiserfs-defrag
echo "SquashFS"
pacman_install_chroot squashfs-tools
echo "SSDFS"
aur_install_chroot ssdfs-tools
echo "SSHFS"
pacman_install_chroot sshfs
echo "UDF"
pacman_install_chroot udftools
echo "XFS"
pacman_install_chroot xfsprogs
echo "ZFS"
aur_install_chroot zfs-dkms zfs-utils
echo "Installing additional file system support complete."
echo "Optimizing battery life..."
aur_install_chroot auto-cpufreq
chroot "${GUESTSNEEZEOS_WORKDIR}" systemctl enable auto-cpufreq
echo "Optimizing battery life complete."
echo "Minimizing writes to the disk..."
chroot "${GUESTSNEEZEOS_WORKDIR}" crudini --set /etc/systemd/journald.conf Journal Storage volatile
echo "Minimizing writes to the disk compelete."
   if [[ "${GUESTSNEEZEOS_XORG}" == "true" ]]; then    
        pacman_install_chroot xorg-server xorg-xinit xorg-xinput xterm xf86-input-libinput xcb-util-keysyms xcb-util-cursor xcb-util-wm xcb-util-xrm
       aur_install_chroot xwayland-run-git weston libwayland-server 
   fi
pacman_install_chroot sddm
mkdir -p "${GUESTSNEEZEOS_WORKDIR}"/etc/sddm.conf.d/
touch "${GUESTSNEEZEOS_WORKDIR}"/etc/sddm.conf.d/uid.conf
chroot "${GUESTSNEEZEOS_WORKDIR}" crudini --set /etc/sddm.conf.d/uid.conf Users MaximumUid 2999
# Set up the SDDM failover handler.
mkdir -p "${GUESTSNEEZEOS_WORKDIR}"/usr/lib/systemd/system/sddm.service.d
cp ../winesapOS/rootfs/usr/lib/systemd/system/winesapos-sddm-health-check.service "${GUESTSNEEZEOS_WORKDIR}"/usr/lib/systemd/system/
cp ../winesapOS/rootfs/usr/local/bin/winesapos-sddm-health-check.sh "${GUESTSNEEZEOS_WORKDIR}"/usr/local/bin/
chroot "${GUESTSNEEZEOS_WORKDIR}" systemctl enable winesapos-sddm-health-check
   if [[ "${GUESTSNEEZEOS_DE}" == "hyprland" ]]; then
       echo "Installing the Hyprland desktop enviorment..."
      pacman_install_chroot hyprland-meta waybar
      echo "Installing the Hyprland desktop enviorment complete."
   elif [[ "${GUESTSNEEZEOS_DE}" == "plasma" ]]; then
       echo "Installing the KDE Plasma desktop environment..."
      pacman_install_chroot plasma-meta plasma-nm
       # Dolphin file manager and related plugins.
      pacman_install_chroot dolphin ffmpegthumbs kdegraphics-thumbnailers konsole
      chroot "${GUESTSNEEZEOS_WORKDIR}" crudini --ini-options=nospace --set /etc/xdg/konsolerc "Desktop Entry" DefaultProfile Vapor.profile
      # Image gallery and text editor.
      pacman_install_chroot gwenview kate
   fi
   mv "${GUESTSNEEZEOS_WORKDIR}"/usr/share/wayland-sessions/plasma.desktop "${GUESTSNEEZEOS_WORKDIR}"/usr/share/wayland-sessions/0plasma.desktop
   echo "Installing the KDE Plasma desktop environment complete."
   chroot "${GUESTSNEEZEOS_WORKDIR}" systemctl enable sddm
# Install Bluetooth.
pacman_install_chroot bluez bluez-utils blueman bluez-qt
chroot "${GUESTSNEEZEOS_WORKDIR}" systemctl enable bluetooth
## This is required to turn Bluetooth on or off.
chroot "${GUESTSNEEZEOS_WORKDIR}" usermod -a -G rfkill "${GUESTSNEEZEOS_USERNAME}"
# Install printer drivers.
pacman_install_chroot cups libcups lib32-libcups bluez-cups cups-pdf usbutils
chroot "${GUESTSNEEZEOS_WORKDIR}" systemctl enable cups
mkdir -p "${GUESTSNEEZEOS_WORKDIR}"/home/"${GUESTSNEEZEOS_USERNAME}"/Desktop/
echo "Setting up the desktop environment complete."
echo 'Setting up the additional package managers...'
aur_install_chroot appimagepool-appimage bauh snapd
chroot "${GUESTSNEEZEOS_WORKDIR}" systemctl enable snapd
# Enable support for classic Snaps.
mkdir -p "${GUESTSNEEZEOS_WORKDIR}"/var/lib/snapd/snap
ln -s /var/lib/snapd/snap "${GUESTSNEEZEOS_WORKDIR}"/snap
   # GameMode. 
    pacman_install_chroot gamemode lib32-gamemode
    # Open Gamepad UI.
    aur_install_chroot opengamepadui-bin
    # Gamescope and Gamescope Session.
    pacman_install_chroot gamescope
    aur_install_chroot gamescope-session-git gamescope-session-steam-git opengamepadui-session-git
    # Nexus Mods app.
    aur_install_chroot nexusmods-app-bin
    # OpenRazer.
    pacman_install_chroot openrazer-daemon openrazer-driver-dkms python-pyqt5 python-openrazer
    aur_install_chroot polychromatic
    chroot "${GUESTSNEEZEOS_WORKDIR}" gpasswd -a "${GUESTSNEEZEOS_USERNAME}" plugdev
    # MangoHud.
    aur_install_chroot mangohud-git lib32-mangohud-git
    # GOverlay.
    aur_install_chroot goverlay-git
    # vkBasalt
    aur_install_chroot vkbasalt lib32-vkbasalt
    # Ludusavi.
    aur_install_chroot ludusavi
    # Steam dependencies.
    pacman_install_chroot gcc-libs libgpg-error libva libxcb lib32-gcc-libs lib32-libgpg-error lib32-libva lib32-libxcb
    # umu-launcher.
    aur_install_chroot umu-launcher
    # ZeroTier VPN.
    pacman_install_chroot zerotier-one
    aur_install_chroot zerotier-gui-git
    # game-devices-udev for more controller support.
    aur_install_chroot game-devices-udev
    # EmuDeck.
    EMUDECK_GITHUB_URL="https://api.github.com/repos/EmuDeck/emudeck-electron/releases/latest"
    EMUDECK_URL="$(curl -s ${EMUDECK_GITHUB_URL} | grep -E 'browser_download_url.*AppImage' | cut -d '"' -f 4)"
    curl --location "${EMUDECK_URL}" --output "${GUESTSNEEZEOS_WORKDIR}"/home/"${GUESTSNEEZEOS_USERNAME}"/Desktop/EmuDeck.AppImage
    chmod +x "${GUESTSNEEZEOS_WORKDIR}"/home/"${GUESTSNEEZEOS_USERNAME}"/Desktop/EmuDeck.AppImage
    # Steam.
    pacman_install_chroot steam steam-native-runtime
    # Steam Tinker Launch.
    aur_install_chroot steamtinkerlaunch
    # Decky Loader.
    ## First install the 'zenity' dependency.
    pacman_install_chroot zenity
    curl --location --remote-name "https://github.com/SteamDeckHomebrew/decky-installer/releases/latest/download/decky_installer.desktop" --output-dir "${WINESAPOS_INSTALL_DIR}"/home/"${WINESAPOS_USER_NAME}"/Desktop/
    chroot "${GUESTSNEEZEOS_WORKDIR}" crudini --ini-options=nospace --set /home/"${GUESTSNEEZEOS_USERNAME}"/Desktop/decky_installer.desktop "Desktop Entry" Icon steam
    # NonSteamLaunchers.
    curl --location --remote-name "https://raw.githubusercontent.com/moraroy/NonSteamLaunchers-On-Steam-Deck/refs/heads/main/NonSteamLaunchers.desktop" --output-dir "${WINESAPOS_INSTALL_DIR}"/home/"${WINESAPOS_USER_NAME}"/Desktop/
    echo "Installing gaming tools complete."
    mkdir -p "${GUESTSNEEZEOS_WORKDIR}"/home/"${GUESTSNEEZEOS_WORKDIR}"/.winesapos/
   cp ../winesapos/rootfs/home/winesap/.winesapos/winesapos-ngfn.desktop "${GUESTSNEEZEOS_WORKDIR}"/home/"${GUESTSNEEZEOS_USERNAME}"/.winesapos/
   cp ../winesapos/rootfs/home/winesap/.winesapos/winesapos-xcloud.desktop "${GUESTSNEEZEOS_WORKDIR}"/home/"${GUESTSNEEZEOS_USERNAME}"/.winesapos/
   sed -i 's/HOOKS=.*/HOOKS=(base microcode udev block keyboard modconf filesystems resume fsck)/g' "${GUESTSNEEZEOS_WORKDIR}"/etc/mkinitcpio.conf
   echo "Completed."
fi