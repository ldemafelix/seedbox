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

Then, set up your library inside the `library` folder. Always change your library's owner to whatever `PUID` and `PGID` you set in the `docker-compose` files. By default, this is `1000` (UID) and `1000` (GID), so to do that:

```
# Set up your library however you want
mkdir -p /var/lib/seedbox/library/{Anime,Movies,Shows}

# Change folder ownership
chown -R 1000:1000 /var/lib/seedbox/library
```

Once the containers are up, you're good to go. VPN traffic is automatically routed through your OpenVPN server. Your OpenVPN config file can be named anything you want, as long as it ends in `.ovpn`.

If you want qBittorrent to automatically run `unrar` after downloading, the correct command to put in qBittorrent's config UI is:

```
unrar x "%F/*.r*" "%F/"
```

To connect Sonarr and Radarr to Jackett, you can use `http://jackett:9117` as your base URL instead of your public IP, as they belong to the same Docker project network.

To update, simply `down` the containers, pull the latest images and run the `up` commands found above again.

# Plex Setup

To run Plex, edit `plex.yml` and set your claim token (you can get this from [https://www.plex.tv/claim/](https://www.plex.tv/claim/). Then, create the working directory and run the Plex `docker-compose` file:

```
# Create Plex directory
mkdir /var/lib/seedbox/plex

# Change folder ownershihp (use the UID and GID in your Sonarr/Radarr docker-compose files)
chown -R 1000:1000 /var/lib/seedbox/plex

# Run the Plex docker-compose file
docker-compose -p seedbox-plex -f plex.yml up -ddocker-compose -p seedbox-plex -f plex.yml up -d
```

Enjoy!
