#!/bin/bash
# Credits:
# Wootar's repository: https://github.com/wootar/steamos-holo-scripts
mkdir -p base/
echo "Server = https://steamdeck-packages.steamos.cloud/archlinux-mirror/$repo/os/$arch" >> base/mirrorlist-steamos
touch base/pacman.conf
base/pacman.conf << EOF
#
# /etc/pacman.conf
#
# See the pacman.conf(5) manpage for option and repository directives

#
# GENERAL OPTIONS
#
[options]
# The following paths are commented out with their default values listed.
# If you wish to use different paths, uncomment and update the paths.
#RootDir     = /
#DBPath      = /var/lib/pacman/
#CacheDir    = /var/cache/pacman/pkg/
#LogFile     = /var/log/pacman.log
#GPGDir      = /etc/pacman.d/gnupg/
#HookDir     = /etc/pacman.d/hooks/
HoldPkg      = pacman glibc
#XferCommand = /usr/bin/curl -L -C - -f -o %o %u
#XferCommand = /usr/bin/wget --passive-ftp -c -O %o %u
#CleanMethod = KeepInstalled
Architecture = auto

# Pacman won't upgrade packages listed in IgnorePkg and members of IgnoreGroup
#IgnorePkg   =
#IgnoreGroup =

#NoUpgrade   =
#NoExtract   =

# Misc options
#UseSyslog
Color
#NoProgressBar
CheckSpace
VerbosePkgLists
ParallelDownloads = 2

# By default, pacman accepts packages signed by keys that its local keyring
# trusts (see pacman-key and its man page), as well as unsigned packages.
#SigLevel    = Required DatabaseOptional
SigLevel = Never
# LocalFileSigLevel = Optional
#RemoteFileSigLevel = Required

# NOTE: You must run `pacman-key --init` before first using pacman; the local
# keyring can then be populated with the keys of all official Artix Linux
# packagers with `pacman-key --populate artix`.

#
# REPOSITORIES
#   - can be defined here or included from another file
#   - pacman will search repositories in the order defined here
#   - local/custom mirrors can be added here or in separate files
#   - repositories listed first will take precedence when packages
#     have identical names, regardless of version number
#   - URLs will have $repo replaced by the name of the current repo
#   - URLs will have $arch replaced by the name of the architecture
#
# Repository entries are of the format:
#       [repo-name]
#       Server = ServerName
#       Include = IncludePath
#
# The header [repo-name] is crucial - it must be present and
# uncommented to enable the repo.
#

# The gremlins repositories are disabled by default. To enable, uncomment the
# repo name header and Include lines. You can add preferred servers immediately
# after the header, and they will be used before the default mirrors.

#[testing]
#Include = /etc/pacman.d/mirrorlist

[jupiter]
Include = /etc/pacman.d/mirrorlist-steamos
SigLevel = Never

[holo]
Include = /etc/pacman.d/mirrorlist-steamos
SigLevel = Never

[core]
Include = /etc/pacman.d/mirrorlist-steamos
SigLevel = Never

[extra]
Include = /etc/pacman.d/mirrorlist-steamos
SigLevel = Never

#[community-testing]
#Include = /etc/pacman.d/mirrorlist

[community]
Include = /etc/pacman.d/mirrorlist-steamos
SigLevel = Never

[multilib]
Include = /etc/pacman.d/mirrorlist-steamos
SigLevel = Never

# An example of a custom package repository.  See the pacman manpage for
# tips on creating your own repositories.
#[custom]
#SigLevel = Optional TrustAll
#Server = file:///home/custompkgs
EOF

mkdir /etc/pacman.d || true
mkdir rootfs || true
cp base/mirrorlist-steamos /etc/pacman.d
pacstrap -M -i -G -C base/pacman.conf rootfs base networkmanager sudo konsole plasma-meta htop neofetch steamdeck-kde-presets steamfs-git steam-jupiter-stable steamos-customizations-jupiter || basestrap -M -i -G -C base/pacman.conf rootfs base networkmanager sudo konsole plasma-meta htop neofetch steamdeck-kde-presets steamfs-git steam-jupiter-stable steamos-customizations-jupiter || echo "Please install arch install scripts"; exit 1
cp base/pacman.conf rootfs/etc/pacman.conf
cp base/mirrorlist-steamos rootfs/etc/pacman.d/mirrorlist-steamos
echo '%wheel ALL=(ALL:ALL) ALL' >> rootfs/etc/sudoers
echo "Please setup a password."
chroot ./rootfs /bin/mkdir /home/steam
chroot ./rootfs /sbin/useradd -G "audio,video,wheel" steam
chroot ./rootfs /bin/chown -v steam /home/steam
chroot ./rootfs /sbin/passwd steam
umount -l rootfs/proc
umount -l rootfs/dev
umount -l rootfs/sys
3rm -frv rootfs
Xephyr -glamor :1 &
sudo mount --bind ./rootfs ./rootfs 
sudo arch-chroot ./rootfs /bin/sh -c "dbus-daemon --system; su -c 'DISPLAY=:1 dbus-launch startplasma-x11' - steam" || sudo artix-chroot ./rootfs /bin/sh -c "dbus-daemon --system; su -c 'DISPLAY=:1 dbus-launch startplasma-x11' - steam"