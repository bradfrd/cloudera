#!/bin/bash

# Set swappiness to 1
echo "Setting swappiness to 1..."
sysctl vm.swappiness=1
echo "vm.swappiness=1" >> /etc/sysctl.conf

# Disable Transparent Huge Pages (THP)
echo "Disabling Transparent Huge Pages..."
echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled
echo 'never' > /sys/kernel/mm/transparent_hugepage/defrag
echo 'if test -f /sys/kernel/mm/transparent_hugepage/enabled; then echo never > /sys/kernel/mm/transparent_hugepage/enabled; fi' >> /etc/rc.d/rc.local
echo 'if test -f /sys/kernel/mm/transparent_hugepage/defrag; then echo never > /sys/kernel/mm/transparent_hugepage/defrag; fi' >> /etc/rc.d/rc.local
chmod +x /etc/rc.d/rc.local

# Enable chronyd
echo "Enabling chronyd..."
systemctl enable chronyd
systemctl start chronyd

# Stop and disable firewalld
echo "Stopping and disabling firewalld..."
systemctl stop firewalld
systemctl disable firewalld

# Disable SELinux
echo "Disabling SELinux..."
sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
setenforce 0

# Disable IPv6
echo "Disabling IPv6..."
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
sysctl -w net.ipv6.conf.lo.disable_ipv6=1
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf

# Apply sysctl settings
sysctl -p

# Set fapolicyd to permissive
# Path to the fapolicyd configuration file
CONFIG_FILE="/etc/fapolicyd/fapolicyd.conf"

# Check if the configuration file exists
if [[ -f "$CONFIG_FILE" ]]; then
    # Backup the original configuration file
    cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"
    echo "Backup of the configuration file created at ${CONFIG_FILE}.bak"

    # Use sed to set fapolicyd mode to permissive
    sed -i 's/^mode=.*$/mode=PERMISSIVE/' "$CONFIG_FILE"
    echo "fapolicyd mode set to PERMISSIVE"

    # Restart fapolicyd to apply changes
    systemctl restart fapolicyd
    echo "fapolicyd service restarted successfully"
else
    echo "Configuration file not found at $CONFIG_FILE"
    exit 1
fi



echo "All tasks completed."

#Explanation:

 #   Swappiness: Sets the swappiness value to 1 and makes it persistent.
 #   THP: Disables Transparent Huge Pages both immediately and at boot.
 #   chronyd: Ensures the chronyd service is enabled and started.
 #   firewalld: Stops and disables the firewall service.
 #   SELinux: Disables SELinux by editing the configuration file and setting it to permissive mode.
 #   IPv6: Disables IPv6 by updating sysctl parameters.
 #   Set fapilicyd to permissive

#To execute, save the script as setup_rhel9.sh, make it executable (chmod +x setup_rhel9.sh), and run it with sudo ./setup_rhel9.sh.