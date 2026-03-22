#!/usr/bin/env bash

# =================================================================
# Author: Dusan Brankov [dbran@tutanota.com]
#
# Description:
#
# Create a new directory for a website and set permissions so that
# it can be accessed by the web server that runs the website.
#
# It is assumed that the website, for which the directory is
# created, is Nginx or Apache. Therefore, by default the group
# ownership is set to 'www-data'.
#
# If a system user needs to have access to the website's directory,
# pass the '-s' option followed by the username.
#
# Caution:
#
# Be aware that users of group and system user have read access to
# all files in the directory, created by mkwwwdir. Further
# restrictions may be necessary for security reasons.
#
# The most common example for such a scenario is storing
# credentials in an '.env' file. Web servers shouldn't have access
# to such files. Either remove read access, or even better, move
# them away from the website's root directory into a dedicated
# directory which is not accessible by the web server and others.
#
# Usage:
#
#	mkwwwdir [-u USERNAME] [-g GROUP] DIR
#
# =================================================================

set -u

print_usage() {
	cat <<EOF
Usage: $0 [OPTION]... DIRETORY

Options:
	-u USER  set the owner of the directory
	-g GROUP set the group of the directory
	-s USER  set permissions for a system user
	-h       show this help message
EOF
}

error() {
	printf "error: %s\n" "$1" >&2
	exit 1
}

if [ $EUID -ne 0 ]; then
	error "this script must be run as root"
fi

while getopts ":u:g:s:h" opt; do
	case $opt in
		u) user="$OPTARG" ;;
		g) group="$OPTARG" ;;
		s) sysuser="$OPTARG" ;;
		h) print_usage; exit ;;
		\?) error "invalid option -$OPTARG"; exit 1 ;;
		:)  error "option -$OPTARG requires an argument"; exit 1 ;;
	esac
done

shift $((OPTIND - 1))

if [ $# -ne 1 ]; then
	print_usage
	error "missing argument: name of directory"
fi

dir="$1"
group="${group:-www-data}"
user="${user:-root}"
sysuser="${sysuser:-}"

if ! getent group "$group" >/dev/null 2>&1; then
	error "group '$group' doesn't exist"
fi

commands=(setfacl getfacl)

for cmd in "${commands[@]}"; do
	if ! command -v "$cmd" >/dev/null 2>&1; then
		error "missing command: $cmd"
	fi
done

# Create directory and set permissions
mkdir "$dir" || exit
chown -c "$user:$group" "$dir"
chmod -c 2750 "$dir"

# Set permissions for given system user
if [ -n "$sysuser" ]; then
	setfacl -d -m u:"$sysuser":rX "$dir"
	setfacl -m u:"$sysuser":rX "$dir"
	getfacl "$dir"
fi

