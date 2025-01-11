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
    rm -rf "${GUESTSNEEZEOS_WORKDIR}"/var/cache/pacman/pkg/*
    rm -rf "${GUESTSNEEZEOS_WORKDIR}"/home/"${GUESTSNEEZEOS_USER_NAME}"/.cache/go-build/*
    rm -rf "${GUESTSNEEZEOS_WORKDIR}"/home/"${GUESTSNEEZEOS_USER_NAME}"/.cache/paru/*
    rm -rf "${GUESTSNEEZEOS_WORKDIR}"/home/"${GUESTSNEEZEOS_USER_NAME}"/.cache/yay/*
    rm -rf "${GUESTSNEEZEOS_WORKDIR}"/home/"${GUESTSNEEZEOS_USER_NAME}"/.cargo/*
    rm -rf "${GUESTSNEEZEOS_WORKDIR}"/tmp/*
}

pacman_install_chroot() {
    chroot "${GUESTSNEEZEOS_WORKDIR}" /usr/bin/pacman --noconfirm -S --needed "$@"
    clear_cache
}

aur_install_chroot() {
    chroot "${GUESTSNEEZEOS_WORKDIR}" sudo -u "${GUESTSNEEZEOS_USER_NAME}" yay --noconfirm -S --removemake "$@"
    clear_cache
}

if [[ "${GUESTSNEEZEOS_CREATE_DEVICE}" == "true" ]]; then

    mkdir ../${GUESTSNEEZEOS_OUTPUT}/

    if [[ -n "${GUESTSNEEZEOS_CREATE_DEVICE_SIZE}" ]]; then
            fallocate -l "${GUESTSNEEZEOS_CREATE_DEVICE_SIZE}GiB" ../output/${OS_NAME}.img
    else
        if [[ "${GUESTSNEEZEOS_ENABLE_PORTABLE_STORAGE}" == "true" ]]; then
            fallocate -l 25GiB ../${GUESTSNEEZEOS_OUTPUT}/${OS_NAME}.img
        else
            fallocate -l 8GiB ../${GUESTSNEEZEOS_OUTPUT}/${OS_NAME}.img
        fi
    fi

    DEVICE="$(losetup --partscan --find --show ../${GUESTSNEEZEOS_OUTPUT}/${OS_NAME}.img)"
    echo "${DEVICE}" | tee /tmp/${OS_NAME}-device.txt
fi

mkdir -p "${GUESTSNEEZEOS_WORKDIR}"

if [[ "${GUESTSNEEZEOS_BUILD_CHROOT_ONLY}" == "false" ]]; then
    DEVICE_WITH_PARTITION="${DEVICE}"
    if echo "${DEVICE}" | grep -q -P "^/dev/(nvme|loop)"; then
        DEVICE_WITH_PARTITION="${DEVICE}p"
    fi

    echo "Creating partitions..."
    if [[ "${GUESTSNEEZEOS_PARTITION_TABLE}" == "gpt" ]]; then
        parted "${DEVICE}" mklabel gpt
    else
        parted "${DEVICE}" mklabel msdos
    fi
    parted "${DEVICE}" mkpart primary 2048s 2MiB

    if [[ "${WINESAPOS_ENABLE_PORTABLE_STORAGE}" == "true" ]]; then
        parted "${DEVICE}" mkpart primary 2MiB 16GiB
        parted "${DEVICE}" set 2 msftdata on
        parted "${DEVICE}" mkpart primary fat32 16GiB 16.5GiB
        parted "${DEVICE}" set 3 esp on
        parted "${DEVICE}" mkpart primary ext4 16.5GiB 17.5GiB
        parted "${DEVICE}" set 4 boot on
        parted "${DEVICE}" mkpart primary btrfs 17.5GiB 100%
    else
        parted "${DEVICE}" mkpart primary fat32 2MiB 512MiB
        parted "${DEVICE}" set 2 esp on
        parted "${DEVICE}" mkpart primary ext4 512MiB 1.5GiB
        parted "${DEVICE}" set 3 boot on
        parted "${DEVICE}" mkpart primary btrfs 1.5GiB 100%
    fi

    sync
    partprobe

    if [[ "${GUESTSNEEZEOS_ENABLE_PORTABLE_STORAGE}" == "true" ]]; then
        mkfs -t exfat "${DEVICE_WITH_PARTITION}2"
        exfatlabel "${DEVICE_WITH_PARTITION}2" gsos-drive
        mkfs -t vfat "${DEVICE_WITH_PARTITION}3"
        fatlabel "${DEVICE_WITH_PARTITION}3" GSOS-EFI
        mkfs -t ext4 "${DEVICE_WITH_PARTITION}4"
        e2label "${DEVICE_WITH_PARTITION}4" guestsneezeos-boot

        if [[ "${GUESTSNEEZEOS_ENCRYPT}" == "true" ]]; then
            echo "${GUESTSNEEZEOS_ENCRYPT_PASSWORD}" | cryptsetup -q luksFormat "${DEVICE_WITH_PARTITION}5"
            cryptsetup config "${DEVICE_WITH_PARTITION}5" --label guestsneezeos-luks
            echo "${GUESTSNEEZEOS_ENCRYPT_PASSWORD}" | cryptsetup luksOpen "${DEVICE_WITH_PARTITION}5" cryptroot
            root_partition="/dev/mapper/cryptroot"
        else
            root_partition="${DEVICE_WITH_PARTITION}5"
        fi

    else
        mkfs -t vfat "${DEVICE_WITH_PARTITION}2"
        fatlabel "${DEVICE_WITH_PARTITION}2" GSOS-EFI
        mkfs -t ext4 "${DEVICE_WITH_PARTITION}3"
        e2label "${DEVICE_WITH_PARTITION}3" guestsneezeos-boot

        if [[ "${GUESTSNEEZEOS_ENCRYPT}" == "true" ]]; then
            echo "${GUESTSNEEZEOS_ENCRYPT_PASSWORD}" | cryptsetup -q luksFormat "${DEVICE_WITH_PARTITION}4"
            cryptsetup config "${DEVICE_WITH_PARTITION}"4 --label guestsneezeos-luks
            echo "${WINESAPOS_ENCRYPT_PASSWORD}" | cryptsetup luksOpen "${DEVICE_WITH_PARTITION}4" cryptroot
            root_partition="/dev/mapper/cryptroot"
        else
            root_partition="${DEVICE_WITH_PARTITION}4"
        fi
    fi

    mkfs -t btrfs "${root_partition}"
    btrfs filesystem label "${root_partition}" guestsneezeos-root
    echo "Creating partitions complete."

    echo "Mounting partitions..."
    mount -t btrfs -o subvol=/,compress-force=zstd:1,discard,noatime,nodiratime "${root_partition}" "${GUESTSNEEZEOS_WORKDIR}"
    btrfs subvolume create "${GUESTSNEEZEOS_WORKDIR}/home"
    mount -t btrfs -o subvol=/home,compress-force=zstd:1,discard,noatime,nodiratime "${root_partition}" "${GUESTSNEEZEOS_WORKDIR}/home"
    btrfs subvolume create "${GUESTSNEEZEOS_WORKDIR}/swap"
    mount -t btrfs -o subvol=/swap,compress-force=zstd:1,discard,noatime,nodiratime "${root_partition}" "${GUESTSNEEZEOS_WORKDIR}/swap"
    mkdir "${GUESTSNEEZEOS_WORKDIR}/boot"
    if [[ "${GUESTSNEEZEOS_ENABLE_PORTABLE_STORAGE}" == "true" ]]; then
        mount -t ext4 "${DEVICE_WITH_PARTITION}4" "${GUESTSNEEZEOS_WORKDIR}/boot"
    else
        mount -t ext4 "${DEVICE_WITH_PARTITION}3" "${GUESTSNEEZEOS_WORKDIR}/boot"
    fi

    mkdir "${GUESTSNEEZEOS_WORKDIR}"/boot/efi
    export efi_partition=""
    if [[ "${GUESTSNEEZEOS_ENABLE_PORTABLE_STORAGE}" == "true" ]]; then
        export efi_partition="${DEVICE_WITH_PARTITION}3"
    else
        export efi_partition="${DEVICE_WITH_PARTITION}2"
    fi

    if [[ "${GUESTSNEEZEOS_BOOTLOADER}" == "grub" ]]; then
        mount -t vfat "${efi_partition}" "${GUESTSNEEZEOS_WORKDIR}/boot/efi"
    elif [[ "${GUESTSNEEZEOS_BOOTLOADER}" == "systemd-boot" ]]; then
        mount -t vfat "${efi_partition}" "${GUESTSNEEZEOS_WORKDIR}/boot"
    fi

    for i in tmp var/log var/tmp; do
        mkdir -p "${GUESTSNEEZEOS_WORKDIR}"/${i}
        mount tmpfs -t tmpfs -o nodev,nosuid "${GUESTSNEEZEOS_WORKDIR}/${i}"
    done

    echo "Mounting partitions complete."
fi

/usr/bin/pacman --noconfirm -S --needed arch-install-scripts
echo "Installing ${GUESTSNEEZEOS_DISTRO} Linux..."

pacstrap -i "${GUESTSNEEZEOS_WORKDIR}" base base-devel curl libeatmydata fwupd --noconfirm

if [ ! -f "${GUESTSNEEZEOS_WORKDIR}/etc/pacman.conf" ]; then
    cp /etc/pacman.conf "${GUESTSNEEZEOS_WORKDIR}"/etc/pacman.conf
else
    sed -i 's/\[options\]/\[options\]\nXferCommand = \/usr\/bin\/curl --connect-timeout 60 --retry 10 --retry-delay 5 -L -C - -f -o %o %u/g' "${GUESTSNEEZEOS_WORKDIR}"/etc/pacman.conf
fi

mount --rbind /dev "${GUESTSNEEZEOS_WORKDIR}"/dev
mount -t proc /proc "${GUESTSNEEZEOS_WORKDIR}"/proc
mount --rbind /sys "${GUESTSNEEZEOS_WORKDIR}"/sys

if [[ "${GUESTSNEEZEOS_DISTRO}" == "arch" ]]; then
    echo "Adding the 32-bit multilb repository..."
    echo -e '\n\n[multilib]\nInclude=/etc/pacman.d/mirrorlist' >> "${GUESTSNEEZEOS_WORKDIR}"/etc/pacman.conf
    echo "Adding the 32-bit multilb repository complete."
fi

rm -f "${GUESTSNEEZEOS_WORKDIR}"/etc/pacman.d/mirrorlist
cp /etc/pacman.d/mirrorlist "${GUESTSNEEZEOS_WORKDIR}"/etc/pacman.d/mirrorlist
chroot "${GUESTSNEEZEOS_WORKDIR}" pacman -S -y
chroot "${GUESTSNEEZEOS_WORKDIR}" pacman -S -y -y

pacman_install_chroot efibootmgr iwd mkinitcpio modem-manager-gui networkmanager usb_modeswitch zram-generator
echo -e "[device]\nwifi.backend=iwd" > "${GUESTSNEEZEOS_WORKDIR}"/etc/NetworkManager/conf.d/wifi_backend.conf
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
echo "${GUESTSNEEZEOS_LOCALE}" >> "${GUESTSNEEZEOS_WORKDIR}"/etc/locale.gen
chroot "${GUESTSNEEZEOS_WORKDIR}" locale-gen
echo "LANG=$(echo "${GUESTSNEEZEOS_LOCALE}" | cut -d' ' -f1)" > "${GUESTSNEEZEOS_WORKDIR}"/etc/locale.conf
echo steamos > "${GUESTSNEEZEOS_WORKDIR}"/etc/hostname
echo "127.0.1.1    steamos" >> "${GUESTSNEEZEOS_WORKDIR}"/etc/hosts
pacman_install_chroot inetutils
pacman_install_chroot fprintd
echo "Installing ${GUESTSNEEZEOS_DISTRO} complete."
pacman_install_chroot spice-vdagent
echo "Setting up Pacman parallel package downloads in chroot..."
sed -i 's/\#ParallelDownloads.*/ParallelDownloads=5/g' "${GUESTSNEEZEOS_WORKDIR}"/etc/pacman.conf
echo "Setting up Pacman parallel package downloads in chroot complete."
if [[ "${GUESTSNEEZEOS_BUILD_CHROOT_ONLY}" == "false" ]]; then
    echo "Saving partition mounts to /etc/fstab..."
    sync
    partprobe
    udevadm trigger
    udevadm settle
    if [[ "${GUESTSNEEZEOS_BOOTLOADER}" == "grub" ]]; then
        echo "LABEL=guestsneezeos-root        	/         	btrfs     	rw,noatime,nodiratime,commit=600,compress-force=zstd:1,discard,space_cache=v2,subvolid=$(btrfs subvolume show /winesapos | grep "Subvolume ID"  | awk '{print $3}'),subvol=/	0 0
LABEL=guestsneezeos-root        	/home     	btrfs     	rw,noatime,nodiratime,commit=600,compress-force=zstd:1,discard,space_cache=v2,subvolid=$(btrfs subvolume show /winesapos/home | grep "Subvolume ID"  | awk '{print $3}'),subvol=/home	0 0
LABEL=guestsneezeos-root        	/swap     	btrfs     	rw,noatime,nodiratime,commit=600,compress-force=zstd:1,discard,space_cache=v2,subvolid=$(btrfs subvolume show /winesapos/swap | grep "Subvolume ID"  | awk '{print $3}'),subvol=/swap	0 0
LABEL=guestsneezeos-boot        	/boot     	ext4      	rw,relatime	0 2
LABEL=GSOS-EFI        	/boot/efi 	vfat      	rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=iso8859-1,shortname=mixed,errors=remount-ro	0 2" > "${GUESTSNEEZEOS_WORKDIR}"/etc/fstab
    echo "tmpfs    /tmp    tmpfs    rw,nosuid,nodev,inode64    0 0
tmpfs    /var/log    tmpfs    rw,nosuid,nodev,inode64    0 0
tmpfs    /var/tmp    tmpfs    rw,nosuid,nodev,inode64    0 0" >> "${GUESTSNEEZEOS_WORKDIR}"/etc/fstab
    elif [[ "${GUESTSNEEZEOS_BOOTLOADER}" == "systemd-boot" ]]; then
        echo "LABEL=winesapos-root        	/         	btrfs     	rw,noatime,nodiratime,commit=600,compress-force=zstd:1,discard,space_cache=v2,subvolid=$(btrfs subvolume show /winesapos | grep "Subvolume ID"  | awk '{print $3}'),subvol=/	0 0
LABEL=guestsneezeos-root        	/home     	btrfs     	rw,noatime,nodiratime,commit=600,compress-force=zstd:1,discard,space_cache=v2,subvolid=$(btrfs subvolume show /winesapos/home | grep "Subvolume ID"  | awk '{print $3}'),subvol=/home	0 0
LABEL=guestsneezeos-root        	/swap     	btrfs     	rw,noatime,nodiratime,commit=600,compress-force=zstd:1,discard,space_cache=v2,subvolid=$(btrfs subvolume show /winesapos/swap | grep "Subvolume ID"  | awk '{print $3}'),subvol=/swap	0 0
LABEL=GSOS-EFI        	/boot 	vfat      	rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=iso8859-1,shortname=mixed,errors=remount-ro	0 2" > "${GUESTSNEEZEOS_WORKDIR}"/etc/fstab
    fi
    echo "tmpfs    /tmp    tmpfs    rw,nosuid,nodev,inode64    0 0
tmpfs    /var/log    tmpfs    rw,nosuid,nodev,inode64    0 0
tmpfs    /var/tmp    tmpfs    rw,nosuid,nodev,inode64    0 0" >> "${GUESTSNEEZEOS_WORKDIR}"/etc/fstab
    echo "View final /etc/fstab file:"
    cat "${GUESTSNEEZEOS_WORKDIR}"/etc/fstab
    echo "Saving partition mounts to /etc/fstab complete."
fi

echo "Configuring fastest mirror in the chroot..."
if [[ "${GUESTSNEEZEOS_DISTRO_DETECTED}" == "arch" ]]; then
    pacman_install_chroot reflector
fi
rm -f "${GUESTSNEEZEOS_WORKDIR}"/etc/pacman.d/mirrorlist
cp /etc/pacman.d/mirrorlist "${GUESTSNEEZEOS_WORKDIR}"/etc/pacman.d/mirrorlist
echo "Configuring fastest mirror in the chroot complete."
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

echo "options radeon si_support=0
options radeon cik_support=0
options amdgpu si_support=1
options amdgpu cik_support=1" >> "${GUESTSNEEZEOS_WORKDIR}"/usr/lib/modprobe.d/winesapos-amd.conf
echo "options amdgpu noretry=0" >> "${GUESTSNEEZEOS_WORKDIR}"/usr/lib/modprobe.d/winesapos-amd.conf
pacman_install_chroot flatpak
echo -e "root\nroot" | chroot "${GUESTSNEEZEOS_WORKDIR}" passwd root
chroot "${GUESTSNEEZEOS_WORKDIR}" useradd --create-home "${GUESTSNEEZEOS_USER_NAME}"
echo -e "${GUESTSNEEZEOS_USER_NAME}\n${GUESTSNEEZEOS_USER_NAME}" | chroot "${GUESTSNEEZEOS_WORKDIR}" passwd "${WINESAPOS_USER_NAME}"
echo "${GUESTSNEEZEOS_USER_NAME} ALL=(root) NOPASSWD:ALL" > "${GUESTSNEEZEOS_WORKDIR}"/etc/sudoers.d/"${WINESAPOS_USER_NAME}"
chmod 0440 "${GUESTSNEEZEOS_WORKDIR}"/etc/sudoers.d/"${GUESTSNEEZEOS_USER_NAME}"
mkdir "${GUESTSNEEZEOS_WORKDIR}"/home/"${GUESTSNEEZEOS_USER_NAME}"/Desktop
chroot "${GUESTSNEEZEOS_WORKDIR}" ln -s /home/"${GUESTSNEEZEOS_USER_NAME}" /home/deck
aur_install_chroot pacman-static
mkdir -p "${GUESTSNEEZEOS_WORKDIR}"/var/lib/winesapos/
chroot "${GUESTSNEEZEOS_WORKDIR}" pacman -S -w --noconfirm broadcom-wl-dkms
for i in $(ls -1 "${GUESTSNEEZEOS_WORKDIR}"/var/cache/pacman/pkg/ | grep broadcom-wl-dkms)
    do cp "${GUESTSNEEZEOS_WORKDIR}"/var/cache/pacman/pkg/"${i}" "${GUESTSNEEZEOS_WORKDIR}"/var/lib/winesapos/
done
pacman_install_chroot libpipewire lib32-libpipewire wireplumber
pacman_install_chroot pipewire-alsa pipewire-jack lib32-pipewire-jack pipewire-pulse pipewire-v4l2 lib32-pipewire-v4l2
mkdir -p "${GUESTSNEEZEOS_WORKDIR}"/home/"${GUESTSNEEZEOS_USER_NAME}"/.config/systemd/user/default.target.wants/
chroot "${GUESTSNEEZEOS_WORKDIR}" ln -s /usr/lib/systemd/user/pipewire.service /home/"${GUESTSNEEZEOS_USER_NAME}"/.config/systemd/user/default.target.wants/pipewire.service
chroot "${GUESTSNEEZEOS_WORKDIR}" ln -s /usr/lib/systemd/user/pipewire-pulse.service /home/"${GUESTSNEEZEOS_USER_NAME}"/.config/systemd/user/default.target.wants/pipewire-pulse.service
cp winesapos-mute.service "${GUESTSNEEZEOS_WORKDIR}"/usr/lib/systemd/user/
cp winesapos-mute.sh "${GUESTSNEEZEOS_WORKDIR}"/usr/local/bin/
chroot "${GUESTSNEEZEOS_WORKDIR}" ln -s /usr/lib/systemd/user/winesapos-mute.service /home/"${GUESTSNEEZEOS_USER_NAME}"/.config/systemd/user/default.target.wants/winesapos-mute.service
pacman_install_chroot pavucontrol
aur_install_chroot firefox-esr
if [[ "${GUESTSNEEZEOS_BUILD_CHROOT_ONLY}" == "false" ]]; then
    echo "Installing the Linux kernels..."
    echo "
[arch-mact2]
Server = https://mirror.funami.tech/arch-mact2/os/x86_64
SigLevel = Never

[Redecorating-t2]
Server = https://github.com/Redecorating/archlinux-t2-packages/releases/download/packages
SigLevel = Never" >> "${GUESTSNEEZEOS_WORKDIR}"/etc/pacman.conf
    chroot "${GUESTSNEEZEOS_WORKDIR}" pacman -S -y
    aur_install_chroot linux-fsync-nobara-bin
    pacman_install_chroot apple-t2-audio-config apple-bcm-firmware

    if [[ "${GUESTSNEEZEOS_DISTRO_DETECTED}" == "manjaro" ]]; then
        pacman_install_chroot linux66 linux66-headers
    else
        pacman_install_chroot core/linux-lts core/linux-lts-headers
    fi

    pacman_install_chroot \
      linux-firmware \
      linux-firmware-bnx2x \
      linux-firmware-liquidio \
      linux-firmware-marvell \
      linux-firmware-mellanox \
      linux-firmware-nfp \
      linux-firmware-qcom \
      linux-firmware-qlogic \
      linux-firmware-whence \
      alsa-firmware \
      sof-firmware \
      mkinitcpio-firmware \
      aw87559-firmware \
      linux-firmware-asus \
      linux-firmware-valve \
      amd-ucode \
      intel-ucode
    echo "Installing the Linux kernels complete."
fi
    # Install Xorg.
    pacman_install_chroot xorg-server xorg-xinit xorg-xinput xterm xf86-input-libinput xcb-util-keysyms xcb-util-cursor xcb-util-wm xcb-util-xrm
    aur_install_chroot xwayland-run-git weston libwayland-server
    # Install SDDM.
    pacman_install_chroot sddm
mkdir -p "${GUESTSNEEZEOS_WORKDIR}"/etc/sddm.conf.d/
touch "${GUESTSNEEZEOS_WORKDIR}"/etc/sddm.conf.d/uid.conf
mkdir -p "${GUESTSNEEZEOS_WORKDIR}"/usr/lib/systemd/system/sddm.service.d
cp winesapos-sddm-health-check.service "${GUESTSNEEZEOS_WORKDIR}"/usr/lib/systemd/system/
cp winesapos-sddm-health-check.sh "${GUESTSNEEZEOS_WORKDIR}"/usr/local/bin/
chroot "${GUESTSNEEZEOS_WORKDIR}" systemctl enable winesapos-sddm-health-check

if [[ "${GUESTSNEEZEOS_DE}" == "cinnamon" ]]; then
    echo "Installing the Cinnamon desktop environment..."
        pacman_install_chroot cinnamon
        pacman_install_chroot maui-pix xed
    if [[ "${GUESTSNEEZEOS_DISTRO_DETECTED}" == "manjaro" ]]; then
        pacman_install_chroot cinnamon-sounds cinnamon-wallpapers manjaro-cinnamon-settings manjaro-settings-manager
        pacman_install_chroot adapta-maia-theme kvantum-manjaro
    fi
    echo "Installing the Cinnamon desktop environment complete."

elif [[ "${GUESTSNEEZEOS_DE}" == "cosmic" ]]; then
    echo "Installing the COSMIC desktop environment..."
    # qt6-tools provides 'qdbus6' which is needed for the first-time setup.
    pacman_install_chroot cosmic-session cosmic-files cosmic-terminal cosmic-text-editor cosmic-wallpapers qt6-tools
    echo "Installing the COSMIC desktop environment complete."

elif [[ "${GUESTSNEEZEOS_DE}" == "gnome" ]]; then
    echo "Installing the GNOME desktop environment...."
    pacman_install_chroot gnome gnome-tweaks
    if [[ "${GUESTSNEEZEOS_DISTRO_DETECTED}" == "manjaro" ]]; then
        pacman_install_chroot manjaro-gnome-settings manjaro-settings-manager
    fi
    echo "Installing the GNOME desktop environment complete."

elif [[ "${GUESTSNEEZEOS_DE}" == "sway" ]]; then
    echo "Installing the Sway tiling manager..."
    pacman_install_chroot dmenu foot sway swaylock swayidle swaybg wmenu
    echo "Installing the Sway tiling manager complete."

elif [[ "${GUESTSNEEZEOS_DE}" == "hyprland" ]]; then
    echo "Installing the Hyprland desktop enviorment..."
    pacman_install_chroot hyprland-meta waybar
    echo "Installing the Hyprland desktop enviorment complete."

elif [[ "${GUESTSNEEZEOS_DE}" == "plasma" ]]; then
    echo "Installing the KDE Plasma desktop environment..."
    pacman_install_chroot plasma-meta plasma-nm
    pacman_install_chroot dolphin ffmpegthumbs kdegraphics-thumbnailers konsole
    pacman_install_chroot gwenview kate

    if [[ "${GUESTSNEEZEOS_DISTRO_DETECTED}" == "manjaro" ]]; then
        pacman_install_chroot manjaro-kde-settings manjaro-settings-manager-knotifier
        pacman_install_chroot plasma6-themes-breath plasma6-themes-breath-extra breath-wallpapers sddm-breath-theme
    fi

    mv "${GUESTSNEEZEOS_WORKDIR}"/usr/share/wayland-sessions/plasma.desktop "${GUESTSNEEZEOS_WORKDIR}"/usr/share/wayland-sessions/0plasma.desktop
    echo "Configuring passwordless login..."
    for i in kde sddm; do
        sudo mv "${GUESTSNEEZEOS_WORKDIR}"/etc/pam.d/"${i}" "${GUESTSNEEZEOS_WORKDIR}"/etc/pam.d/"${i}"BAK
        echo -e "auth\tsufficient\tpam_succeed_if.so\tuser\tingroup\tnopasswdlogin" | sudo tee "${GUESTSNEEZEOS_WORKDIR}"/etc/pam.d/"${i}"
        sudo cat "${GUESTSNEEZEOS_WORKDIR}"/etc/pam.d/"${i}"BAK | sudo tee -a "${GUESTSNEEZEOS_WORKDIR}"/etc/pam.d/"${i}"
        sudo rm -f "${GUESTSNEEZEOS_WORKDIR}"/etc/pam.d/"${i}"BAK
    done
    chroot "${GUESTSNEEZEOS_WORKDIR}" groupadd nopasswdlogin
    chroot "${GUESTSNEEZEOS_WORKDIR}" usermod -a -G nopasswdlogin "${GUESTSNEEZEOS_USER_NAME}"
    echo "InputMethod=qtvirtualkeyboard" | sudo tee "${GUESTSNEEZEOS_WORKDIR}"/etc/sddm.conf.d/winesapos.conf
    echo "Configuring passwordless login complete."
    echo "Installing the KDE Plasma desktop environment complete."
    chroot "${GUESTSNEEZEOS_WORKDIR}" systemctl enable sddm
pacman_install_chroot bluez bluez-utils blueman bluez-qt
chroot "${GUESTSNEEZEOS_WORKDIR}" systemctl enable bluetooth
chroot "${GUESTSNEEZEOS_WORKDIR}" usermod -a -G rfkill "${GUESTSNEEZEOS_USER_NAME}"
pacman_install_chroot cups cups-pdf libcups lib32-libcups bluez-cups cups-pdf usbutils
chroot "${GUESTSNEEZEOS_WORKDIR}" systemctl enable cups
mkdir -p "${GUESTSNEEZEOS_WORKDIR}"/home/"${GUESTSNEEZEOS_USER_NAME}"/Desktop/
