# PlexAmp Headless Running on Docker
In short, this repository provides instructions and a docker container for running PlexAmp headless on ARM, ARM64, and AMD64 machines.

## What/Why/How?
PlexAmp is an audio player/stream receiver that plays audio files and lists stored in your plex server.  The headless version allows you to run it on a machine with a gui and allows control via web interface or via streaming from the desktop or mobile version. For this reason, it makes a great audio player endpoint for home audio and other embedded style setups.

## Reporting issues / getting help
Please open an issue on the project here: [Project Issues]([https://gitlab.com/zonywhoop/plexamp-headless-docker/-/issues](https://github.com/pmdroid/plexamp-headless-docker/issues))

## The Build
### The Host Machine
The player machine MUST have an audio controller of some sort available. The instructions below have been tested on Raspbian for pi3 and pi4 along with Ubuntu 20 and 22 on amd64. Also note that here we are using `podman` vs `docker` but I've tested both and you can interchange `docker` with `podman` in the instructions.

#### Ubuntu 20.04
**Setup Podman**

Instructions for other distro's available on [their website](https://podman.io/getting-started/installation)

```BASH
sudo apt install -y curl wget gnupg2

source /etc/os-release && sudo sh -c "echo 'deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/ /' > sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list"

wget -nv https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_${VERSION_ID}/Release.key -O- | sudo apt-key add -

sudo apt-get update -qq -y

sudo apt-get -qq --yes install podman

sudo podman --version
```
Add the following to the bottom of `/etc/containers/registries.conf` 
* NOTE: This is only needed for `podman`!!
```TOML
[registries.insecure]
registries = [ ]
# If you need to block pull access from a registry, uncomment the section below
# and add the registries fully-qualified name.
# Docker only
[registries.block]
registries = [ ]
```

#### Setup Raspbian
Installing Podman for Rasbian is very easy.
```BASH
apt install podman
```

### Setting up Audio
Ensure you have Alsa setup and configured, running the following should show 1 or more devices:
```BASH
ls -l /dev/snd/*
```

Additionally, it is important to ensure that no other audio applications are running and using Alsa at the same time. If you need to run multiple apps (such as shairport-sync) it you may need to look at using [PulseAdudio](Docs/Pulseaudio.md) alongside Alsa.


## Usage
### Prep local storage
Next we need to create a folder for PlexAmp to store it's configuration files, here you can create a local system user that matches what plexamp runs as OR you can just create a directory that is owned by the uid/gid that plexamp runs as.

Note that creating a local user may be required to ensure proper access to the /dev audio devices
```BASH
sudo groupadd -g 1001 plexamp
sudo useradd -u 1001 -g 1001 -G -G audio,video,render \
  --home /opt/plexamp plexamp
```


Or just create the folder and ensure it's owned by the user plexamp runs as:
```BASH
sudo mkdir /opt/plexamp
sudo chown 1001:1001 /opt/plexamp
sudo chmod 775 /opt/plexamp
```

### The container
#### Image Tags
We build 3 different images for each released version of Plexamp Headless.  These are:
* amd64 [linux/amd64]
* arm [linux/arm/v7]
* arm64 [linux/arm64/v8] 

The tag format looks like this:
`ghcr.io/pmdroid/plexamp-headless-docker:arm-4111:amd64-461     image: docker pull ghcr.io/pmdroid/plexamp-headless-docker:(platform)-(version)` so for version 4.5.0 on amd64 the docker tag would be `ghcr.io/pmdroid/plexamp-headless-docker:arm-4111:amd64-461     image: docker pull ghcr.io/pmdroid/plexamp-headless-docker:amd64-450`

#### Initial Startup
Here we can start the container for the first time. Note we have to run this container in interactive mode at the console so we can claim the player and setup it's cookie:

```BASH
sudo podman run -it --privileged \
  --mount type=bind,src=/opt/plexamp,dst=/home/plexamp \
  --mount type=bind,src=/run,dst=/run \
  --network=host \
  --name plexamp \
  ghcr.io/pmdroid/plexamp-headless-docker:arm-4111:amd64-461     image: docker pull ghcr.io/pmdroid/plexamp-headless-docker:amd64-461
```

#### Recurring Startup
Once you walk through the initial setup process and claim the player, hit `ctrl-c` to exit PlexAmp so we can then run it as a detached container.

```BASH
sudo podman run -d --privileged --restart unless-stopped \
  --mount type=bind,src=/opt/plexamp,dst=/home/plexamp \
  --mount type=bind,src=/run,dst=/run \
  --network=host \
  --name plexamp \
  ghcr.io/pmdroid/plexamp-headless-docker:arm-4111:amd64-461     image: docker pull ghcr.io/pmdroid/plexamp-headless-docker:amd64-461
```

### Docker Compose
Below is a `docker-compose.yml` file known to work:

```YAML
version: '3'
services:
  lms:
    container_name: plexamp
    privileged: true
    network_mode: "host"
    image: ghcr.io/pmdroid/plexamp-headless-docker:arm-4111:amd64-461     image: docker pull ghcr.io/pmdroid/plexamp-headless-docker:amd64-461
    volumes:
      - /data/docker/plexamp/:/home/plexamp:rw
      - /run:/run:rw
    restart: unless-stopped
```

## In container updates
You can update Plexamp Headless to the latest release in-container by running the following:
```BASH
podman exec -it plexamp /usr/local/bin/update_plexamp
```
* Substitue the `plexamp` above with the name of the container on your system!


That's it! You should now be able to access PlexAmp at `http://device.ip:32500`. 
