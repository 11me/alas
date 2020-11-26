#!/bin/sh

# Script automatically installs ArchLinux.
# Make sure your block device is empty, ie means it has no partitions.

printf "Enter a new password for user Root: "
stty -echo
read -r pass
stty echo
echo " "

printf "Enter a hostname: "
read -r host

printf "Enter a lowercase letter of your block device: a,b,c,d: "
read -r block

printf "Enter size of swap in Gb: "
read -r swp

printf "Enter size of root in Gb: "
read -r root

cat <<EOF | fdisk "/dev/sd${block}"
g
n


+512M
n
t
1
n


+${swp}G
n


+${root}G
n



w
EOF
partprobe

mkswap "/dev/sd${block}2"
swapon "/dev/sd${block}2"
yes | mkfs.fat -F32 "/dev/sd${block}1"
yes | mkfs.ext4 "/dev/sd${block}3"
yes | mkfs.ext4 "/dev/sd${block}4"

mount "/dev/sd${block}3" /mnt
mkdir -p /mnt/efi
mkdir -p /mnt/home
mount "/dev/sd${block}1" /mnt/efi
mount "/dev/sd${block}4" /mnt/home

pacstrap /mnt base base-devel linux linux-firmware man-db man-pages neovim

genfstab -U /mnt >> /mnt/etc/fstab

# Copy the chroot script to the new installed environment
cp -r ../../alas /mnt/root
arch-chroot /mnt /root/alas/arch_installer/chroot.sh "$pass" "$host"
