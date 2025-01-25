#!/bin/bash
Xephyr -glamor :1 &
sudo mount --bind ./rootfs ./rootfs 
sudo arch-chroot ./rootfs /bin/sh -c "dbus-daemon --system; su -c 'DISPLAY=:1 dbus-launch startplasma-x11' - steam" || sudo artix-chroot ./rootfs /bin/sh -c "dbus-daemon --system; su -c 'DISPLAY=:1 dbus-launch startplasma-x11' - steam"