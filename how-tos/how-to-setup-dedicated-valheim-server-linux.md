# How to setup a dedicated Valheim server on Linux (Debian)

When I first started playing, I wanted to set up a dedicated server for my friends and I. The existing guides were a bit sparse, or were missing important information for my specific needs. I wrote this up as I set up my server, thought maybe it would be useful to others. Of course the better alternative to this is to pay for a dedicated hosting provider, but I'd rather not..

This guide assumes a fresh Debian install on a `sudo` user, not root.

Start by installing the required packages on your `sudo` user. We'll create a dedicated user to run the server on next.

### Install SteamCMD

[According to Valve](https://developer.valvesoftware.com/wiki/SteamCMD#Debian), you must add the non-free repository and add x86 packages. It specifically references [this Stackoverflow question/answer](https://stackoverflow.com/questions/76688863/apt-add-repository-doesnt-work-on-debian-12/78720328#78720328)
```
sudo apt -y install software-properties-common
sudo dpkg --add-architecture i386
sudo add-apt-repository -y -n -U http://deb.debian.org/debian -c non-free -c non-free-firmware
sudo apt update
sudo apt install steamcmd
```

### Install crossplay repositories

This may not be necessary for you, but it was for me. Without these packages, I couldn't connect to my server, but I could if I removed the `-crossplay` flag from the `start_server.sh` script below. So skip if you don't need, but if you want console players to be able to join, this is required.

```
sudo apt install install libpulse-dev libatomic1 libc6
```

I found this out [here](https://web.archive.org/web/20250221174549/https://discourse.cubecoders.com/t/valheim-server-not-accessible/2048), but apparently they learned it from somewhere else on Reddit, no idea where.

### Dedicated user

Next, create a dedicated user to run the server. There's no good reason to run the server as `sudo`, at least not in most people's case. We'll eventually create the server as a system service and run it under this user. We're making the user "steam", feel free to set it whatever you want. The -m flag creates the user's home directory i.e /home/steam.

```
sudo useradd -m steam
sudo passwd steam
```

### Download the Valheim dedicated server files

Launch the `steamcmd` terminal, designate where you're installing the server files, and then download them. `force_install_dir` must be run before logging in.
```
steamcmd
Steam> force_install_dir /home/steam/valheim
Steam> login anonymous
Steam> app_update 896660 validate 
Steam> exit
```

### Configure server

Now configure your server, specifically the name of the server, the name of the world, and the server's password. The `-crossplay` flag is optional. If you're having issues, try removing it to test.

```
nano /home/steam/valheim/start_server.sh
```

```
#!/bin/bash
export templdpath=$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=./linux64:$LD_LIBRARY_PATH
export SteamAppId=892970

echo "Starting server PRESS CTRL-C to exit"

# Tip: Make a local copy of this script to avoid it being overwritten by steam.
# NOTE: Minimum password length is 5 characters & Password cant be in the server name.
# NOTE: You need to make sure the ports 2456-2458 is being forwarded to your server through your local router & firewal>
./valheim_server.x86_64 -name "YOUSERVERNAME" -port 2456 -world "YOURWORLDNAME" -password "YOURPASSWORD" -crossplay

export LD_LIBRARY_PATH=$templdpath
```

### Configure the server as a background service

Doing this will allow you to exit the ssh terminal to your server and/or log out, without the server closing, i.e it runs as a background service.

Start by making the server script executable

```
sudo chmod +x /home/steam/valheim/start_server.sh
```

And then create the service file

```
sudo nano /etc/systemd/system/valheim.service // you can name it whatever you want
```

Now paste the following:

```
[Unit]
Description=Valheim Server
After=network.target

[Service]
Type=simple
User=steam
WorkingDirectory=/home/steam/valheim
ExecStart=/home/steam/valheim/start_server.sh
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

Notice the service is being run as the `steam` user. Also make sure to specify the location of the server script to avoid errors. Now start the service:

```
sudo systemctl start valheim.server
```

You can view the live server output with the following:

```
sudo journalctl -fu valheim
```

### Open ports

Finally, you need to open the necessary ports for Valheim, [which are 2456-2457](https://www.valheimgame.com/support/a-guide-to-dedicated-servers/). If you're hosting this on a computer on your local network (I don't recommend), you'll need to portforward them on your router.

I use a VPS, so I'm just going to use `ufw` to enable/open them. Don't disconnect from the `ssh` session until you allow port 22 or you may get locked out of the server.
```
sudo apt install ufw -y
sudo ufw enable
sudo ufw allow 22     //ssh
sudo ufw allow 2456   //valheim
sudo ufw allow 2457   //valheim
```

And there you go, you should now be able to access your server using its IP and password you set earlier. 

### Import your world from another PC

In my case, I had created a world on a Windows PC. It automatically was saved to Steam's cloud, so I had to start by moving it to local, and then copying it to my dedicated server. These notes may not be 100%, I got annoyed trying to transfer the world, but it was new so we just started over.

Move the world to local if it's saved in Steam's cloud:
- Launch Valheim
- Start Game
- Start
- Select the world you want to move to local in the Select World window
- Manage Saves
- Select the Save you want to move to local in the Manage Saves window
- Click 'Move to local'

Say your save name was "test_world", you would now see `test_world_backup_20250217-000902.db` and `test_world_backup_20250217-000902.fwl` in `C:\Users\You\AppData\LocalLow\IronGate\Valheim\worlds_local`. For simplicity, rename these to `test_world.db` and `test_world.fwl`.

To copy those files via ssh, run the following:
`scp <local_file_path> <username>@<remote_host>:<remote_path>`

So for our example:
```
scp C:\Users\You\AppData\LocalLow\IronGate\Valheim\worlds_local\test_world.db you@your-server:/home/steam
```
and
```
scp C:\Users\You\AppData\LocalLow\IronGate\Valheim\worlds_local\test_world.fwl you@your-server:/home/steam
```

When you log into your server, you would likely be transported to the starting area. If that's the case, you may need to also copy the `.fch` files from `C:\Program Files (x86)\Steam\userdata\[YOUR_USER_NUMBER]\892970\remote\characters` to the new character folder. Like I said, you're kind of on your own with this last step.
