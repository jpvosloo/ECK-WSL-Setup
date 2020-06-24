#!/bin/bash
echo "This script will install Canonical MicroK8s on a pre-installed Ubuntu."
read -p "Press ENTER to continue ..."

# Install the required packages for SystemD
apt install -yqq fontconfig daemonize
# Creates a default user and adds it to the sudo group
useradd -m -s /bin/bash -G sudo mk8s
# Reset the password of the default user
passwd mk8s
# Edit the sudoers to remove the password request
visudo
    %sudo   ALL=(ALL:ALL) NOPASSWD: ALL
	# Edit the sudoers to remove the password request
