# How to autoupdate mods for AzuAntiCheat on a dedicated Valheim server on Linux (Debian)

This guide assumes you followed the guide to [setup AzuAntiCheat](/how-tos/how-to-setup-azuanticheat-valheim-server-linux.md) on your dedicated server. Using the [autoupdate_mods.sh](/scripts/autoupdate_mods.sh) script, we can automatically update all of our mods on the server, including BepInEx, AzuAntiCheat, and our whitelisted/greylisted mods. This way, you can install new mod versions from the Thunderstore app on your client without intervention.

In the [setup AzuAntiCheat guide](/how-tos/how-to-setup-azuanticheat-valheim-server-linux.md), we downloaded our mods into `BepInEx/plugins` using the following scheme:
```
namespace/name/version
```

- `namespace` = The mod creator e.g [Azumatt](https://thunderstore.io/c/valheim/p/Azumatt/)
- `name` = The name of the mod e.g [AzuAntiCheat](https://thunderstore.io/c/valheim/p/Azumatt/AzuAntiCheat/)
- `version` = The version of the mod

The script parses the `json` response from the `api_v1_package_metrics` endpoint for the `latest_version` of our installed mod, and then updates them if necessary.
