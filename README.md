# PlexAmp Headless Running on amd64
In short, this repository provides instructions and a docker container for running PlexAmp headless (which is released for the Raspberry Pi) on any x64 based linux machine.

## What/Why/How?
The Raspberry Pi 4, which PlexAmp headless is released for, uses an arm64 based CPU. In order to get the code to run on a x64 based cpu we use qemu-static to emulate an arm64 CPU. Note that this does add additional overhead to the process, but in my testing on a 1.6Ghz quad-core Intel NUC it consumes the cpu of a roughly 1 core and only stutters a little here and there.

## Reporting issues / getting help
Please open an issue on the project here: [Project Issues](https://gitlab.com/zonywhoop/plexamp-headless-x64/-/issues)

## The Build
### The Host Machine
On your HTPC / audio player / etc you must do the following in order to get things setup properly. At the moment only Ubuntu 20.04 has been tested and documented. If you run something else pleaes submit an MR so we can include those builds as well.

Also note that here we are using `podman` vs `docker` but I've tested both and you can interchange `docker` with `podman` in the instructions.

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

Setup qemu-user-static for multi-arch support
```BASH
sudo apt-get install qemu binfmt-support qemu-user-static
sudo podman run --rm --privileged multiarch/qemu-user-static --reset -p yes
```

Now reboot the host and try to run:
```BASH
sudo podman run --rm -t arm64v8/ubuntu uname -m
```
You're output should look something like this:
```
✔ docker.io/arm64v8/ubuntu:latest
Trying to pull docker.io/arm64v8/ubuntu:latest...
Getting image source signatures
Copying blob ed02c6ade914 done
Copying config a7870fd478 done
Writing manifest to image destination
Storing signatures
aarch64
```
If you see `aarch64` at the end then you are good to go!

**Setup PulseAudio**

Noe that for these instructions are setting up PulseAudio at the system level for a dedicated audio player.
#### Install PulseAudio
```
sudo apt install pulseaudio pulsemixer pulseaudio-utils ubuntu-sounds
sudo systemctl --global disable pulseaudio.service pulseaudio.socket
```
#### Setup Pulse system wide
Create systemd file `/etc/systemd/system/pulseaudio-system.service`
```
[Unit]
Description=PulseAudio Daemon

[Install]
WantedBy=multi-user.target

[Service]
Type=simple
PrivateTmp=true
ExecStart=/usr/bin/pulseaudio --system --realtime --disallow-exit --no-cpu-limit 
```

#### Allow anonymous connections - REALLY BAD IF NET ACCESS IS ALLOWED!
```
sudo nano /etc/pulse/system.pa 
Find: module-native-protocol-unix/load-module 
Change to: module-native-protocol-unix auth-anonymous=1
```

#### Make sure root has access to pulse
```
sudo usermod -aG pulse-access root
sudo systemctl daemon-reload
sudo systemctl enable pulseaudio-system
sudo systemctl start pulseaudio-system
```

**Prepare for launch**

Next we need to create a folder for PlexAmp to store it's configuration files:
```BASH
sudo mkdir /opt/plexamp
sudo chown -R 1001:1001 /opt/plexamp
```

### The container
Here we can start the container for the first time. Note we have to run this container in interactive mode at the console so we can claim the player and setup it's cookie:

```BASH
sudo podman run --rm -it --platform arm64 \
  --mount type=bind,src=/run/pulse,dst=/run/pulse \
  --mount type=bind,src=/opt/plexamp/,dst=/home/plexamp/ \
  --network=host \
  registry.gitlab.com/zonywhoop/plexamp-headless-x64:v4.2.2
```

Once you walk through the initial setup process and claim the player, hit `ctrl-c` to exit PlexAmp so we can then run it as a detached container.
```BASH
sudo podman run -d --platform arm64 \
  --mount type=bind,src=/run/pulse,dst=/run/pulse \
  --mount type=bind,src=/opt/plexamp/,dst=/home/plexamp/ \
  --network=host \
  registry.gitlab.com/zonywhoop/plexamp-headless-x64:v4.2.2
```
That's it! You should now be able to access PlexAmp at `http://device.ip:32500`. 

podman run -d --rm --privileged \
  --mount type=bind,src=/home/plexamp,dst=/home/plexamp \
  --mount type=bind,src=/run,dst=/run \
  --ipc=host \
  --network=host \
  -e PLEXAMP_JACK=1 \
  --ulimit rtprio=95 --ulimit rttime=-1 --ulimit memlock=-1 \
  --name plexamp \
  --workdir /app/plexamp \
  registry.gitlab.com/zonywhoop/plexamp-headless-x64:sj1032 \
  node js/index.js 

podman run -d --rm --privileged \
  --mount type=bind,src=/home/plexamp,dst=/home/plexamp \
  --mount type=bind,src=/run,dst=/run \
  --ipc=host \
  --network=host \
  --ulimit rtprio=95 --ulimit rttime=-1 --ulimit memlock=-1 \
  --name snapjack \
  --workdir /app/snapjack \
  registry.gitlab.com/zonywhoop/plexamp-headless-x64:sj1032

  node js/index.js /home/plexamp/.config/snapjack/Config.json
