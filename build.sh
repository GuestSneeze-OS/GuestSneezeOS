#!/bin/bash
echo 'Installing Required Packages'
sudo pacman -S archiso git
echo 'Building ISO...'
sudo mkarchiso -v -w ../out -o ../out ../GuestSneezeOS

