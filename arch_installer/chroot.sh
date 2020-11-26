#!/bin/sh

readonly PASSWORD=$1
readonly HOSTNAME=$2

clear
echo "root:$PASSWORD" | chpasswd

ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc

echo LANG=en_US.UTF-8 >> /etc/locale.conf
{
    echo en_US.UTF-8 UTF-8
    echo en_US ISO-8859-1
    echo ru_RU.UTF-8 UTF-8
    echo ru_RU ISO-8859-5

} >> /etc/locale.gen

locale-gen

echo "$HOSTNAME" >> /etc/hostname
{
    echo "127.0.0.1	localhost"
    echo  "::1		localhost"
    echo  "127.0.1.1	${HOSTNAME}.localdomain	$HOSTNAME"

} >> /etc/hosts

# Install networkmanager and enable it
pacman --noconfirm --needed -S networkmanager
systemctl enable NetworkManager

# Install bootloader
pacman --noconfirm --needed -S grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB && grub-mkconfig -o /boot/grub/grub.cfg
