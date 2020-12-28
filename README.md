# Seedbox via Docker

These are `docker-compose` files that set up the following:

* OpenVPN
* qBittorrent (Web UI Port 8080)
* Jackett (Port 9117)
* Sonarr v3 (Port 8989)
* Radarr v3 (Port 7878)

# Installation

Ensure you have `docker` and `docker-compose` on your server. Then:

```
# Create folders for the docker-compose projects
mkdir -p /var/lib/seedbox/{downloads,jackett,library,qbittorrent,radarr,sonarr,vpn}

# Set up the downloader
cp /path/to/your/vpn/config.ovpn /var/lib/seedbox/vpn/config.ovpn
docker-compose -p seedbox-downloader -f downloader.yml up -d

# Set up the managers (Jackett, Sonarr and Radarr)
docker-compose -p seedbox-manager -f manager.yml up -d
```

Once the containers are up, you're good to go. VPN traffic is automatically routed through your OpenVPN server. Your OpenVPN config file can be named anything you want, as long as it ends in `.ovpn`.

If you want qBittorrent to automatically run `unrar` after downloading, the correct command to put in qBittorrent's config UI is:

```
unrar x "%F/*.r*" "%F/"
```

To connect Sonarr and Radarr to Jackett, you can use `http://jackett:9117` as your base URL instead of your public IP, as they belong to the same Docker project network.

To update, simply `down` the containers, pull the latest images and run the `up` commands found above again.

Enjoy!
