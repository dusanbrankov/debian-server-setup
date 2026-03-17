#!/usr/bin/env bash

# ================================================================
# Create dir, mostly under '/var/www', and set default permissions
# ================================================================

# Ensure the script is run as root
if [ $EUID -ne 0 ]; then
	echo "this script must be run as root" >&2
	exit 1
fi

dir="$1"

# sudo mkdir perm
#     2 sudo chown -c $USER:www-data perm
#     1 sudo chmod -c g+s perm
#   12  touch perm/foo

mkdir "$dir" || exit
chown -c "$SUDO_USER":www-data "$dir"
chmod -c 2750 "$dir"
setfacl -d -m u::rwX -m u:ghost:rX -m g::rX -m o::000 "$dir"
setfacl -m u:ghost:rx "$dir"
getfacl "$dir"

echo "success, now cd into '$dir' and run 'git clone repo .'"

