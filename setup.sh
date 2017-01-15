#!/bin/bash
#
# MIFYUPLOADER.SH SCRIPT.
# ----------------------
#
# This script is designed for you to be able to run the
# "mify file.png" command from anywhere in your terminal
# client and for it to work.

##################################
if [ ! $(id -u) -ne 0 ]; then
 	echo "ERROR : This script cannot be run as sudo."
 	echo "ERROR : You need to remove the sudo from \"sudo ./setup.sh\"."
 	exit 1
fi
 ##################################

if [ "${1}" = "--uninstall" ]; then

	rm /usr/local/bin/mify
	echo "INFO  : Uninstallation of mify.sh finished!"
	echo "INFO  : However APT packages have not been removed."

	exit 0
fi

##################################

scriptdir=$(dirname $(which $0))
mifydir="$HOME/.config/mify"

if [ ! -d $mifydir ]; then
	mkdir $mifydir
	cp -r $scriptdir/* $mifydir
fi

# Give directory ownership to the actual user
chown -R $(whoami | awk '{print $1}') $mifydir

# Create a symbolic link to /usr/local/bin
sudo ln -s $mifydir/script.sh /usr/local/bin/mify

function is_mac() {
	uname | grep -q "Darwin"
}


# Install dependencies
if is_mac; then
	echo "INFO  : Dependencies are unavailable for Mac."
	echo "INFO  : Please run \"mify --check\" to check later on."
else
	(which notify-send &>/dev/null && echo "FOUND : found screencapture") || apt-get install notify-send
	(which maim &>/dev/null && echo "FOUND : found maim") || apt-get install maim
	(which xclip &>/dev/null && echo "FOUND : found xclip") || apt-get install xclip
fi

# Tell the user its done!
echo "INFO  : Installation finished of mify.sh. Use it like \"mify file.png\""
echo "The config is in ~/.config/mify"
