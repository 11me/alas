#!/bin/bash

# Script for installing virtual-manager and qemu
# Run this script as sudo
pacman -S --noconfirm --needed qemu virt-manager libvirt ebtables dnsmasq \
    bridge-utils edk2-ovmf
usermod -aG kvm libvirt lime
