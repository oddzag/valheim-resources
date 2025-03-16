# How to setup AzuAntiCheat on a dedicated Valheim server on Linux (Debian)

Personally, I prefer Valheim as vanilla as possible, I only like using a few QOL mods, but I don't want players to install/use mods that "cheat" on my server. To do this, you can use AzuAntiCheat and its white/grey listing feature. The whitelist **REQUIRES** specified mods, while the greylist **ALLOWS** specified mods. 

I wrote this to follow up my [dedicated server setup guide](/how-tos/how-to-setup-dedicated-valheim-server-linux.md). There's even less guides for AzuAntiCheat out there..

**IMPORTANT**:
- This has not been tested with crossplay. I assume it's not compatible, as the preconfigured BepInEx disables crossplay.
- Vanilla players will **NOT** be able to connect if this is configured. If they attempt to without BepInEx and AzuAntiCheat installed, they will get the message "Incompatible version"

### Install BepInEx

We're using [denikson's](https://thunderstore.io/c/valheim/p/denikson/) preconfigured [BepInEx](https://thunderstore.io/c/valheim/p/denikson/BepInExPack_Valheim/) for Valheim (now maintained by [Azumatt](https://discord.gg/pdHgy6Bsng), [Margmas](https://discord.gg/DdUt6g7gyA) and [Vapok](https://discord.gg/zUa3efgPxm))

Start by downloading the BepInEx files. As of writing this, it's version `5.4.2202`. The `--content-disposition` flag is because the manual download link on [thunderstore.io](https://thunderstore.io) doesn't point directly to the `.zip` file - presumably due to new updates being added.

To keep everything organized, I'm creating a `BepInExDownload` directory, downloading and unzipping the files, rezipping the necessary files, moving them to the server directory, and deleting everything else. It's intentionally verbose. Feel free to deviate.

Switch to your `sudo` user and stop the server, then switch back to the `steam` user.
```
su - yourSudoUser
sudo systemctl stop valheim
su - steam
```

```
mkdir /home/steam/BepInExDownload
cd /home/steam/BepInExDownload
wget --content-disposition https://thunderstore.io/package/download/denikson/BepInExPack_Valheim/5.4.2202/
unzip denikson-BepInExPack_Valheim-5.4.2202.zip
cd BepInExPack_Valheim
zip -r /home/steam/valheim/BepInEx.zip *
cd /home/steam/valheim
unzip BepInEx.zip
rm -R BepInEx.zip
rm -R /home/steam/BepInExDownload
```

In addition to your regular server files, you'll see the following:
```
changelog.txt
doorstop_config.ini
start_game_bepinex.sh
start_server_bepinex.sh
winhttp.dll
BepInEx/
doortstop_libs/
```

Since this is a headless debian server, you can remove the unnecessary stuff:
```
rm -R changelog.txt start_game_bepinex.sh winhttp.dll
```

So now your current server directory should look like this:
```
ls
 BepInEx                                docker_start_server.sh   start_server.sh           steamapps
 UnityPlayer.so                         doorstop_config.ini      start_server_bepinex.sh   steamclient.so
'Valheim Dedicated Server Manual.pdf'   doorstop_libs            start_server_xterm.sh     valheim_server.x86_64
 docker                                 linux64                  steam_appid.txt           valheim_server_Data
```

Copy the settings from the `start_server.sh` script, specifically `YOURSERVERNAME`, `YOURWORLDNAME` and `YOURPASSWORD`, into the `start_server_bepinex.sh`

```
nano start_server_bepinex.sh
```

```
#!/bin/sh
# BepInEx-specific settings
# NOTE: Do not edit unless you know what you are doing!
####
export DOORSTOP_ENABLE=TRUE
export DOORSTOP_INVOKE_DLL_PATH=./BepInEx/core/BepInEx.Preloader.dll
export DOORSTOP_CORLIB_OVERRIDE_PATH=./unstripped_corlib

export LD_LIBRARY_PATH="./doorstop_libs:$LD_LIBRARY_PATH"
export LD_PRELOAD="libdoorstop_x64.so:$LD_PRELOAD"
####


export LD_LIBRARY_PATH="./linux64:$LD_LIBRARY_PATH"
export SteamAppId=892970

echo "Starting server PRESS CTRL-C to exit"

# Tip: Make a local copy of this script to avoid it being overwritten by steam.
# NOTE: Minimum password length is 5 characters & Password cant be in the server name.
# NOTE: You need to make sure the ports 2456-2458 is being forwarded to your server through your local router & firewall.
exec ./valheim_server.x86_64 -name "YOURSERVERNAME" -port 2456 -world "YOURWORLDNAME" -password "YOURPASSWORD"
```

Since we set up the server to run as a background service, we need to edit that service to use the new `start_server_bepinex.sh` script. Specifically, change the `ExecStart` parameter from `/home/steam/valheim/start_server.sh` to `/home/steam/valheim/_start_server_bepinex.sh`. 

Switch to your `sudo` user and make the changes: 
```
su - yourSudoUser
sudo nano /etc/systemd/system/valheim.service
```
```
[Unit]
Description=Valheim Server
After=network.target

[Service]
Type=simple
User=steam
WorkingDirectory=/home/steam/valheim/
ExecStart=/home/steam/valheim/start_server_bepinex.sh
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

Now reload the services manager. Don't restart the server yet, we'll do that later.
```
sudo systemctl daemon-reload
```

Next, switch back to the `steam` user and make the new BepInEx server script executable.
```
su - steam
chmod +x /home/steam/valheim/start_server_bepinex.sh
```

BepInEx is now installed on our server. Now we need to install AzuAntiCheat and whitelist our mods.

### Install AzuAntiCheat

On a Windows PC using Thunderstore, mods are installed in the `BepInEx/plugins` folder:
```
C:\Users\YOURNAME\AppData\Roaming\Thunderstore Mod Manager\DataFolder\Valheim\profiles\YOURPROFILENAME\BepInEx\plugins
```

On our server, they're located in the valheim server directory, specifically:
```
/home/steam/valheim/BepInEx/plugins
```

Download and install [AzuAntiCheat](https://thunderstore.io/c/valheim/p/Azumatt/AzuAntiCheat/). As of writing this, the current version is 4.3.8. In order to [auto update our mods](/how-tos/how-to-autoupdate-mods-valheim-server-linux.md) later on, we're going to setup these initial mods with the following scheme in our `plugins` folder:

```
namespace/name/version
```

In this case:
- `namespace` = Azumatt
- `name` = AzuAntiCheat
- `version` = 4.3.8

This is following [Thunderstore's API](https://thunderstore.io/api/docs/), so that we can use our [autoupdate_mods]() script to automatically download and white/greylist new mod versions. 

```
cd /home/steam/valheim/BepInEx/plugins
mkdir Azumatt/AzuAntiCheat
cd Azumatt/AzuAntiCheat
```

Now get AzuAntiCheat's manual download link from the Thunderstore here: [Azumatt/AzuAntiCheat](https://thunderstore.io/package/download/Azumatt/AzuAntiCheat). You can see below that the time of writing this, the current version was 4.3.8. So download the zip, and create the corresponding version subdirectory. This only needs to be once if you setup the [autoupdate](/scripts/autoupdate_mods.sh) script.
```
wget --content-disposition https://thunderstore.io/package/download/Azumatt/AzuAntiCheat/4.3.8/
mkdir 4.3.8
unzip *.zip -d 4.3.8/
rm -R *.zip
```

AzuAntiCheat is now installed, just like that. Next, we need to whitelist the mods we want. To do so, we need to get the mod's `dll` file and put it in `BepInEx/config/AzuAntiCheat_Whitelist`. However, that directory doesn't yet exist. It is generated, along with several other files/directories, when the server is started.

Before you start the server, take a look in `/home/steam/valheim/BepInEx`, you should see the following:
```
config  core  patchers  plugins
```

One way to know if BepInEx was properly installed when the server is running, is there will be a `LogOutput.log` file here. If the server is started/running and that file is not there, BepInEx is not installed properly. If that's the case, check your system service and server files ownership. You can also rename `start_server.sh` to something else to see if the system service is running that instead of `start_server_bepinex.sh`.

Switch to your sudo user and start your server to generate the necessary files. I prefer to stop the server when adding/whitelisting new mods, which I'm going to do now, but it may not be necessary.
```
su - yourSudoUser
sudo systemctl restart valheim.service
```

Now when you check `/home/steam/valheim/BepInEx`, you should see the following:
```
ls /home/steam/valheim/BepInEx
LogOutput.log  cache  config  core  patchers  plugins
```

Next, we'll download and white/grey list our mods. But first, stop the server 
```
sudo systemctl stop valheim.service
```

### Greylist your mods

At this point, if the server were running and you attempted to join by launching the game via steam, you'd get the message "Incompatible version"

If you attempted to join by launching the Modded game via Thunderstore, you'd see the following message, since we have no mods white/greylisted:
```
You have been kicked; Banned
Mods Detected (Not on whitelist or greylist)
``` 

Start by switching back to your `steam` user and copying the BepInEx and AzuAntiCheat `dll` to the whitelist folder:
```
su - steam
cd /home/steam/valheim/BepInEx
cp plugins/Valheim.DisplayBepInExInfo.dll config/AzuAntiCheat_Whitelist
cp plugins/Azumatt-AzuAntiCheat/AzuAnticheat.dll config/AzuAntiCheat_Whitelist
```

Next, let's greylist a mod, we'll start with [TeleportEverything](https://thunderstore.io/c/valheim/p/OdinPlus/TeleportEverything/) by OdinPlus. Just as we did with AzuAntiCheat, we'll download TeleportEverything following the `namespace/name/version` scheme in order to allow for [automatically updating our mods](/how-tos/how-to-autoupdate-mods-valheim-server-linux.md). Then copy the mod's `dll` to the AzuAntiCheats Greylist folder.

```
cd /home/steam/valheim/BepInEx/plugins
mkdir OdinPlus/TeleportEverything
cd OdinPlus/TeleportEverything
wget --content-disposition https://thunderstore.io/package/download/OdinPlus/TeleportEverything/2.7.0/
mkdir 2.7.0
unzip OdinPlus-TeleportEverything-2.7.0.zip -d 2.7.0/
rm -R *.zip
cp 2.7.0/TeleportEverything.dll ../../config/AzuAntiCheat_Greylist
```

Now you need to install your mods using Thunderstore. [Here's a great guide](https://archive.fo/f8huE) by [DatHost](https://dathost.net/). You **NEED** to have AzuAntiCheat. When you install it, it'll automatically download BepInEx_Valheim. If you followed this guide strictly, you **CAN** install TeleportEverything.

Finally, restart your server
```
sudo systemctl start valheim
```
You should now be able to launch modded Valheim and connect to the server!
