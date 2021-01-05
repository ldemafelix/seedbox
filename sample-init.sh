#!/bin/bash

# Check if we're running as root
if [ "x$(id -u)" != 'x0' ]; then
    echo "Error: Please run me as root."
    exit 1
fi

# Declare variables
HOSTNAME=`hostname -f`
IPV4=`curl -4 checkip.amazonaws.com`

# Confirm installation
echo "Your hostname is $HOSTNAME. Make sure that it points to your IP address ($IPV4) before continuing. This script will continue in 10 seconds. To cancel, press CTRL + C."
sleep 10

# Create authorized_keys file
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ7Lvdy2/uoj40lxc62kG9ZCO5GrSVebodHOHdwx1RXn Liam Demafelix <hey@liam.ph>" > /etc/ssh/authorized_keys
echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
echo "AuthorizedKeysFile /etc/ssh/authorized_keys" >> /etc/ssh/sshd_config
systemctl restart sshd

# Update the repository cache
apt-get update -y

# Install some pre-requisites
apt-get -y install wget curl zip unzip apt-transport-https ca-certificates curl gnupg-agent software-properties-common zip unzip

# Install rclone
curl https://rclone.org/install.sh | sudo bash

# Add Docker's GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

# Add Docker's repository
add-apt-repository --yes "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Update the repository cache again, just to be sure
apt-get update -y

# Install Docker
apt-get -y install docker-ce docker-ce-cli containerd.io
systemctl enable --now docker.service

# Install docker-compose
curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Create Jellyfin user
adduser --disabled-password --shell /bin/bash jellyfin

# Install Caddy
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/cfg/gpg/gpg.155B6D79CA56EA34.key' | sudo apt-key add -
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/cfg/setup/config.deb.txt?distro=debian&version=any-version' | sudo tee -a /etc/apt/sources.list.d/caddy-stable.list
sudo apt update -y
sudo apt install caddy -y

# Create config
rm -f /etc/caddy/Caddyfile
cat >/etc/caddy/Caddyfile <<EOL
${HOSTNAME} {
    reverse_proxy 127.0.0.1:8096
}
EOL

# Enable caddy
systemctl daemon-reload
systemctl enable caddy
systemctl restart caddy
