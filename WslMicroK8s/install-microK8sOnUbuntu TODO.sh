#!/bin/bash
echo "This script will install Canonical MicroK8s on an existing Ubuntu."

# Install the required packages for SystemD
apt install -yqq fontconfig daemonize

# Creates a default user and adds it to the sudo group
#useradd -m -s /bin/bash -G sudo mk8s
# Reset the password of the default user
#passwd mk8s
# Edit the sudoers to remove the password request
#visudo    %sudo   ALL=(ALL:ALL) NOPASSWD: ALL

#If systemd don't exist then create it.
SYSTEMD_PID=$(ps -ef | grep '/lib/systemd/systemd --system-unit=basic.target$' | grep -v unshare | awk '{print $2}')
if [ -z "$SYSTEMD_PID" ]; then
	apt install daemonize
	cp wsl.conf /etc/wsl.conf
	cp 00-wsl2-systemd.sh /etc/profile.d/00-wsl2-systemd.sh
	echo 'DNS=8.8.8.8' | sudo tee -a /etc/systemd/resolved.conf
fi

# Forward all localhost ports to default interface
echo 'net.ipv4.conf.all.route_localnet = 1' | sudo tee -a /etc/sysctl.conf
# Apply the change
sudo sysctl -p /etc/sysctl.conf

sudo mkdir -p /run/dbus
sudo dbus-daemon --system
sudo daemonize /usr/bin/unshare --fork --pid --mount-proc /lib/systemd/systemd --system-unit=basic.target
sudo apt update

#you may have to restart windows a few times here.
#Installing Docker-Desktop for WSL and enablind kubernetes may help...
#Back in WSL if the systemctl command fail debug it or restart windows a few more times.

	#restart wsl
	wsl --shutdown
	wsl

#Restart services
sudo systemctl restart systemd-resolved
sudo apt update

# List all installed snap packages
snap list

# List all the information from the Microk8s snap
snap info microk8s
