### Setup PulseAudio

**_Note, this is optional!_**

Now that for these instructions are setting up PulseAudio at the system level for a dedicated audio player.
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
