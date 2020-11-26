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

# Update the repository cache
apt-get update -y

# Install some pre-requisites
apt-get -y install wget curl zip unzip apt-transport-https ca-certificates curl gnupg-agent software-properties-common

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

# Create seedbox user
useradd --home-dir /var/lib/seedbox --shell /usr/sbin/nologin --comment "Seedbox" seedbox

# Prepare the seedbox config directories
mkdir -p /etc/seedbox/vpn
chown -R seedbox:seedbox /etc/seedbox
mkdir -p /var/lib/seedbox/{sonarr,radarr,jackett}
chown -R seedbox:seedbox /var/lib/seedbox

# Install Caddy
wget "https://caddyserver.com/api/download?os=linux&arch=amd64&idempotency=59710938683335" -O /usr/bin/caddy
chmod +x /usr/bin/caddy
groupadd --system caddy
useradd --system \
    --gid caddy \
    --create-home \
    --home-dir /var/lib/caddy \
    --shell /usr/sbin/nologin \
    --comment "Caddy web server" \
    caddy

# Create systemd unit file
tee /etc/systemd/system/caddy.service << END
[Unit]
Description=Caddy
Documentation=https://caddyserver.com/docs/
After=network.target network-online.target
Requires=network-online.target

[Service]
User=caddy
Group=caddy
ExecStart=/usr/bin/caddy run --environ --config /etc/caddy/Caddyfile
ExecReload=/usr/bin/caddy reload --config /etc/caddy/Caddyfile
TimeoutStopSec=5s
LimitNOFILE=1048576
LimitNPROC=512
PrivateTmp=true
ProtectSystem=full
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
END

# Create config
mkdir /etc/caddy
cat >/etc/caddy/Caddyfile <<EOL
${HOSTNAME} {
    reverse_proxy /jackett/ http://127.0.0.1:9117/
    reverse_proxy /sonarr/ http://127.0.0.1:8989/
    reverse_proxy /radarr/ http://127.0.0.1:7878/
}
EOL

# Enable caddy
systemctl daemon-reload
systemctl enable caddy
systemctl restart caddy