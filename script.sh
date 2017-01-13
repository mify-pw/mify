#!/bin/bash
#                                   _                 _
#                                  | |               | |
#   _____      _____    _   _ _ __ | | ___   __ _  __| | ___ _ __
#  / _ \ \ /\ / / _ \  | | | | '_ \| |/ _ \ / _` |/ _` |/ _ \ '__|
#  |(_) \ V  V / (_)|  | |_| | |_) | | (_) | (_| | (_| |  __/ |
#  \___/ \_/\_/ \___/   \__,_| .__/|_|\___/ \__,_|\__,_|\___|_|
#                            | |
#                            |_|
#
# mifyUPLOADER.SH SCRIPT.
# ----------------------
#
# This script allows for native support to upload to the image server
# and url shortener component of whats-th.is. Through this you can do
# plethora of actions.
#
# A big thank you to jomo/imgur-screenshot to which I've edited parts
# of his script into my own.

if [ ! $(id -u) -ne 0 ]; then
	echo "ERROR : This script cannot be run as sudo."
	echo "ERROR : You need to remove the sudo from \"sudo ./setup.sh\"."
	exit 1
fi

current_version="v0.0.1"

##################################

mifydir="$HOME/.config/mify"

if [ ! -d $mifydir ]; then
	echo "INFO  : Could not find config directory. Please run setup.sh"
	exit 1
fi

if [ ! -d $path]; then
	mkdir -p $path
fi
source $mifydir/conf.cfg

key=$userkey >&2
output_url=$finished_url >&2

directoryname=$scr_directory >&2
filename=$scr_filename >&2
path=$scr_path >&2

print_debug=$debug >&2

##################################

function is_mac() {
	uname | grep -q "Darwin"
}



function notify() {
	if is_mac; then
		/usr/local/bin/terminal-notifier -title mify.pw -message "${1}" -appIcon $mifydir/icon.icns
	else
		notify-send mify.pw "${1}" -i $mifydir/icon.png
	fi
}

function delete_scr() {
	if [ "$keep_scr" != "true" ]; then
		rm "$path$filename"
	fi
}


function screenshot() {

	# Alert the user that the upload has begun.
	notify "Select an area to begin the upload."

	# Begin our screen capture.
	if is_mac; then
		screencapture -o -i $path$filename
	else
		maim -s $path$filename
	fi

	# Make a directory for our user if it doesnt already exsist.
	mkdir -p $path

	# Open our new entry to use it!
	entry=$path$filename
	upload=$(curl -s -F "files[]=@"$entry";type=image/png" "https://mify.pw/upload")


		echo $upload

	if egrep -q '"success":\s*true' <<< "${upload}"; then
		item="$(egrep -o '"url":\s*"[^"]+"' <<<"${upload}" | cut -d "\"" -f 4)"
		d=$1
		if [ "$d" = true ]; then
			if [ "$scr_copy" = true ]; then
				if is_mac; then
					echo "https://i.mify.pw/$item" | pbcopy
				else
					echo "https://i.mify.pw/$item" | xclip -i -sel c -f | xclip -i -sel p
				fi
				notify "Upload complete! Copied the link to your clipboard."
			else
				echo "https://i.mify.pw/$item"
			fi
		else
			output="https://i.mify.pw/$item"
		fi
	else
		notify "Upload failed! Please check your logs ($mifydir/log.txt) for details."
		echo "UPLOAD FAILED" > $mifydir/log.txt
		echo "The server left the following response" >> $mifydir/log.txt
		echo "--------------------------------------" >> $mifydir/log.txt
		echo " " >> $mifydir/log.txt
		echo "    " $upload >> $mifydir/log.txt
	fi
	delete_scr
}

function upload() {

	entry=$1
	mimetype=$(file -b --mime-type $entry)

		filesize=$(wc -c <"$entry")
		if [[ $filesize -le 83886081 ]]; then
			upload=$(curl -s -F "files[]=@"$entry";type=$mimetype" https://mify.pw/upload)
			item="$(egrep -o '"url":\s*"[^"]+"' <<<"${upload}" | cut -d "\"" -f 4)"
		else
			echo "ERROR : File size too large or another error occured!"
			exit 1
		fi

	if [ "$print_debug" = true ] ; then
		echo $upload
	fi

	d=$2
	if [ "$d" = true ]; then
		echo "RESP  : $upload"
		echo "URL   : https://i.mify.pw/$item"
	else
		output="https://i.mify.pw/$item"
	fi
}

function runupdate() {
	cp $mifydir/conf.cfg $mifydir/conf_backup_$current_version.cfg

	git -C pull origin stable
}

##################################

if [ "${1}" = "-h" ] || [ "${1}" = "--help" ]; then
	echo "usage: ${0} [-h | --check | -v]"
	echo ""
	echo "   -h --help                  Show this help screen to you."
	echo "   -v --version               Show current application version."
	echo "   -c --check                 Checks if dependencies are installed."
	echo "      --update                Checks if theres an update available."
	echo "   -l --shorten               Begins the url shortening process."
	echo "   -s --screenshot            Begins the screenshot uploading process."
	echo "   -sl                        Takes a screenshot and shortens the URL."
	echo "   -ul                        Uploads file and shortens URL."
	echo ""
	exit 0
fi

##################################

if [ "${1}" = "-v" ] || [ "${1}" = "--version" ]; then
	echo "INFO  : You are on version $current_version"
	exit 0
fi

##################################

if [ "${1}" = "-c" ] || [ "${1}" = "--check" ]; then
	if is_mac; then
		(which terminal-notifier &>/dev/null && echo "FOUND : found terminal-notifier") || echo "ERROR : terminal-notifier not found"
		(which screencapture &>/dev/null && echo "FOUND : found screencapture") || echo "ERROR : screencapture not found"
		(which pbcopy &>/dev/null && echo "FOUND : found pbcopy") || echo "ERROR : pbcopy not found"
	else
		(which notify-send &>/dev/null && echo "FOUND : found notify-send") || echo "ERROR : notify-send (from libnotify-bin) not found"
		(which maim &>/dev/null && echo "FOUND : found maim") || echo "ERROR : maim not found"
		(which xclip &>/dev/null && echo "FOUND : found xclip") || echo "ERROR : xclip not found"
	fi
	(which curl &>/dev/null && echo "FOUND : found curl") || echo "ERROR : curl not found"
	(which grep &>/dev/null && echo "FOUND : found grep") || echo "ERROR : grep not found"
	exit 0
fi

##################################

if [ "${1}" = "--update" ]; then
	remote_version="$(curl --compressed -fsSL --stderr - "https://api.github.com/repos/mify-pw/mify.sh/releases" | egrep -m 1 --color 'tag_name":\s*".*"' | cut -d '"' -f 4)"
	if [ "${?}" -eq "0" ]; then
		if [ ! "${current_version}" = "${remote_version}" ] && [ ! -z "${current_version}" ] && [ ! -z "${remote_version}" ]; then
			echo "INFO  : Update found!"
			echo "INFO  : Version ${remote_version} is available (You have ${current_version})"

			echo "ALERT : You already have a configuration file in $mifydir"
			echo "ALERT : Updating might break this config, are you sure you want to update?"

			read -p "INFO  : Continue anyway? (Y/N)" choice
			case "$choice" in
				y|Y ) runupdate;;
n|N ) exit 0;;
* ) echo "ERROR : That is an invalid response, (Y)es/(N)o.";;
esac


elif [ -z "${current_version}" ] || [ -z "${remote_version}" ]; then
	echo "ERROR : Version string is invalid."
	echo "INFO  : Current (local) version: '${current_version}'"
	echo "INFO  : Latest (remote) version: '${remote_version}'"
else
	echo "INFO  : Version ${current_version} is up to date."
fi
else
	echo "ERROR : Failed to check for latest version: ${remote_version}"
fi

exit 0
fi


##################################

if [ "${1}" = "-s" ] || [ "${1}" = "--screenshot" ]; then
	screenshot true
	exit 0
fi

##################################

upload ${1} true
if is_mac; then
    echo $output | pbcopy
else
    echo $output | xclip -i -sel c -f | xclip -i -sel p
fi
notify "Copied link to keyboard."
