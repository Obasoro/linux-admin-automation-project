# All output will be logged to /var/log/system_maintenance/

# Weekly system inventory (Sunday at 3am)
0 3 * * 0 root /usr/bin/system_inventory.sh >> /var/log/maintenance/inventory.log 2>&1

# Hourly network monitoring (at :15 past the hour)
15 * * * * root /usr/bin/network_monitor.sh >> /var/log/maintenance/network.log 2>&1

# Daily backups (at 2am)
0 2 * * * root /usr/bin/backup_manager.sh >> /var/log/maintenance/backup.log 2>&1

# Daily system updates (at 4am with automatic reboots if needed
0 4 * * * root (yum update && yum upgrade -y && yum autoremove -y) >> /var/logmaintenance/updates.log 2>&1
