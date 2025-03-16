#!/bin/bash
# oddzag/valheim-resources
# autobackup.sh

# SET THESE BEFORE RUNNING
server_backups_dir="/opt/valheim/backups/server"  # Directory to store server backups
server_backups_max=3                              # Max number of server backups to keep

world_backups_dir="/opt/valheim/backups/world"    # Directory to store world backups
world_backups_max=3                               # Max number of world backups to keep

echo "// BEGIN VALHEIM SERVER/WORLD BACKUP"
echo "// SHUTTING DOWN SERVER"
systemctl stop valheim

# SERVER BACKUP
echo "// BEGIN SERVER BACKUP"
backup_count=$(find "$server_backups_dir" -mindepth 1 -maxdepth 1 -name '*.tar.gz' -type f | wc -l)

if [[ $backup_count -gt $server_backups_max ]]; then
    echo "// SERVER BACKUP COUNT EXCEEDED, DELETING OLDEST BACKUP"
    find "$server_backups_dir" -mindepth 1 -maxdepth 1 -name '*.tar.gz' -type f -printf '%T@ %p\n' | sort -n | head -n 1 | cut -d ' ' -f 2- | xargs rm -f
fi

cd /home/steam/valheim && tar --exclude='valheim_server_Data' -czf $server_backups_dir/"$(date '+%Y-%m-%d_%H-%M-%S').tar.gz" * || echo "// ERROR OCCURRED, SKIPPING SERVER BACKUP"
echo "// END SERVER BACKUP"

# WORLD BACKUP
echo "// BEGIN WORLD BACKUP"
backup_count=$(find "$world_backups_dir" -mindepth 1 -maxdepth 1 -name '*.tar.gz' -type f | wc -l)

if [[ $backup_count -gt $world_backups_max ]]; then
    echo "// SERVER BACKUP COUNT EXCEEDED, DELETING OLDEST BACKUP"
    find "$world_backups_dir" -mindepth 1 -maxdepth 1 -name '*.tar.gz' -type f -printf '%T@ %p\n' | sort -n | head -n 1 | cut -d ' ' -f 2- | xargs rm -f
fi

cd /home/steam/.config/unity3d/IronGate/Valheim/worlds_local && tar -czf $world_backups_dir/"$(date '+%Y-%m-%d_%H-%M-%S').tar.gz" *
echo "// END WORLD BACKUP"

echo "// BACKUP COMPLETE"
echo "// RESTARTING VALHEIM SERVER"
systemctl start valheim
