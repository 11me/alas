#!/bin/sh

# ArchLinux Autorising Script
# Created by 11me


# ************************************************************************** #
# ----------------------- VARIABLES AND FUNCTION DEFINITIONS --------------- #
# ************************************************************************** #

readonly group="wheel"
readonly aurhelper="yay"
readonly repo_git="https://github.com/11me/dotfiles"
readonly dotfiles="dotfiles" # dotfiles repo name
readonly dmenu_git="https://github.com/11me/dmenu"
readonly st_git="https://github.com/11me/st"
readonly slock_git="https://github.com/11me/slock-1.4.git"

# DO NOT EDIT THIS
readonly backlight_rules="https://gitlab.com/wavexx/acpilight/-/blob/master/90-backlight.rules"
readonly script_dir=$(pwd)

# Just to be polite
welcome_msg() {

    clear
    printf "\n"
    printf "***********************************************\n"
    printf "*** Welcome to ArchLinux Autorising Script! ***\n"
    printf "***********************************************\n"
    printf "\n"

}

# Installation loop, goes through the programs.csv file and installs programs
install_loop() {

    total_programs=$(wc -l < "$script_dir/programs.csv")
    i=0
    while IFS=, read -r tag package comment; do
        i=$((i+1))
        printf "Installing $i of $total_programs\n"
        case "$tag" in
            "A") aurinstall "$package" "$comment";;
            "V") maininstall "$package" "$comment";;
        esac
    done < "$script_dir/programs.csv"


}

# Get and validate a username
# params: username
get_username() {
    printf "Please enter the following for a new user\n"
    printf "Username: "
    read username
    while ! echo "$username" | grep "^[a-z_][a-z0-9_-]*$" >/dev/null 2>&1; do
       printf "Username is not valid, please enter it again: "
       read username
	done
}

# Get password from user and validate it
# params: password
get_password() {
    stty -echo
    printf "Password: "
    read pass1
    printf "\n"
    printf "Retype password: "
    read pass2
    printf "\n"

    while ! [ "$pass1" = "$pass2" ]; do
        unset pass2
        printf "Passwords do not match. Enter passwords again.\n"
        printf "Password: "
        read pass1
        printf "\n"
        printf "Retype password: "
        read pass2
    done;

    stty echo
    password=$pass1
    printf "\n"
}

# Create a user
# params: username
create_user(){

    printf "Creating a user - $username...\n"
    useradd -m -G wheel "$username"
    echo "$username:$pass1" | chpasswd
    unset pass1 pass2
    printf "$username successfully created!\n"

}

# Add permissions to the sudoers file
change_sudoers() {

    echo "%$group ALL=(ALL) ALL" >> /etc/sudoers

}

# Copy dotfiles from github repository
# params: url
copy_dotfiles() {

    upath="/home/$username"
    cd "$upath"
    printf "Navigating to $upath\n"
    printf "Pulling dotfiles from github...\n"
    git clone "$repo_git" > /dev/null 2>&1
    chown -R "$username:$group" "$dotfiles"

}

# Installs AUR helper
# params: helper_name (default is yay)
aurhelper_install() {

    printf "Downloading $1...\n"
	rm -rf /tmp/"$1"*
    cd "/tmp"
	curl -sO "https://aur.archlinux.org/cgit/aur.git/snapshot/"$1".tar.gz" &&
	sudo -u "$username" tar -xvf "$1".tar.gz >/dev/null 2>&1 &&
	cd "/tmp/$1" &&
	sudo -u "$username" makepkg --noconfirm -si >/dev/null 2>&1
    printf "$1 is installed\n"

}

# Install programs from AUR
# params: package_name
aurinstall() {

    sudo -u "$username" yay -S --noconfirm "$1" >/dev/null 2>&1;

}

# Install programs from ArchLinux repository
# params: package_name
maininstall() {

    pacman --noconfirm --needed -S  "$1" >/dev/null 2>&1;

}

# Create symlinks from dotfiles to user's home folder
make_symlinks() {

     printf "Almost done! Creating symlinks from dotfiles...\n"
     cd "/home/$username"
     ln -sf "$dotfiles/.config" . && chown -R "$username:$group" ".config"
     ln -sf "$dotfiles/.local" . && chown -R "$username:$group" ".local"
     ln -sf "$dotfiles/.zprofile" ".profile" && chown -R "$username:$group" ".profile"
     ln -sf "$dotfiles/.xinitrc" . && chown -R "$username:$group" ".xinitrc"
     ln -sf "$dotfiles/.xprofile" . && chown -R "$username:$group" ".xprofile"
     ln -sf "$dotfiles/.config/zsh/.zshrc" . && chown -R "$username:$group" ".zshrc"

}

# Create working directories
create_dirs() {

    mkdir -p "/home/$username/dox"
    mkdir -p "/home/$username/dwns"
    mkdir -p "/home/$username/pix"
    mkdir -p "/home/$username/dox/{projects,personal,usb-mnt}"

}

# Install software like dwm, st, dmenu from git repository
# params: link, folder_name
install_from_git() {

    cd "/home/$username/.local/share"
    printf "Cloning $2...\n"
    git clone "$1" > /dev/null 2>&1
    chown -R "$username:$group" "$2"
    printf "Installing $2...\n"
    cd "$2"
    make install > /dev/null 2>&1
    printf "$2 installed\n"

}

# Turn off that annoying beep sound
systembeep() {

  	rmmod pcspkr
	echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf

}

# Setup the brightness control
brightness_rules() {

    yes | pacman -S --needed --confirm "acpilight" >/dev/null 2>&1;
    curl -sO -T /etc/udev/rules.d/ $backlight_rules

}

# Tell the user about the end of installation
finally() {

    clear
    printf "Installation complete. All done. Reboot your system now.\n"

}

# ************************************************************************** #
# ------------------------------ MAIN LOGIC -------------------------------- #
# ************************************************************************** #

# Just to be polite
welcome_msg

# Create a user with password
get_username
get_password
create_user
change_sudoers

# Install packages for further installation process
maininstall curl
maininstall wget
aurhelper_install "$aurhelper"
aurinstall "xkb-switch"

copy_dotfiles
make_symlinks

# Run the main installation loop
install_loop

# Install libxft-bgra-git package for emoji
yes | sudo -u "$username" "$aurhelper" -S libxft-bgra-git

# Install software from users git repository
install_from_git "$dmenu_git" dmenu
install_from_git "$st_git" st
install_from_git "$slock_git" "slock-1.4"

chsh -s /bin/zsh "$username" > /dev/null 2>&1
systembeep
create_dirs
brightness_rules
finally
