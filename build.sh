#!/bin/bash
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Please use sudo." 1>&2
   exit 1
fi
sudo rm -rf out/ work/
sudo src/archiso/archiso/mkarchiso -v -w work/ -o out/ src/ 

