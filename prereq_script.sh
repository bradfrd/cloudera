

#echo "hostname;rhel version;kernel version;IPV6;THP;tuned-adm;swappiness;ulimit-n;umask;entropy;ulimit -u;threads-max;file-max;selinux;java;jdk;ntp;dirty_ratio;dirty_background_ratio;min-free;zone-reclaim;cmdline;sda scheduler;w;CPU;MEM;MTU9000;MaxConns;netstat failed connection;netstat socket overflowed;dns_lookup_kdc;dropped packets;connections in wait;connections established;dns;" > hosts_check && \
#for h in $(cat all_hosts \
#); do ssh -o StrictHostKeyChecking=no $h 'echo "$(hostname -f);$(cat /etc/redhat-release);$(uname -r);$(/usr/sbin/ip a |grep inet6 |wc -l);$(cat /sys/kernel/mm/transparent_hugepage/enabled);$(/usr/sbin/tuned-adm list |grep active);$(cat /proc/sys/vm/swappiness);$(ulimit -n);$(umask);$(cat /proc/sys/kernel/random/entropy_avail);$(ulimit -u);$(cat /proc/sys/kernel/threads-max);$(cat /proc/sys/fs/file-max);$(/usr/sbin/getenforce);$(java -version 2>&1|grep version);$(javac -version 2>&1|grep javac);$(ntpq -p 2>&1|grep \*);$(cat /proc/sys/vm/dirty_ratio);$(cat /proc/sys/vm/dirty_background_ratio);$(cat /proc/sys/vm/min_free_kbytes);$(cat /proc/sys/vm/zone_reclaim_mode);$(cat /proc/cmdline | rev | cut -d" " -f1,2 | rev);$(cat /sys/block/sda/queue/scheduler);$(w|head -1);$(lscpu|egrep "Model name|Socket"|cut -d":" -f2|tr -d "[[:blank:]]"|tr "\n" "x");$(cat /proc/meminfo|grep MemTotal|cut -d":" -f2|tr -d "[[:blank:]]");$(ifconfig |grep "mtu 9000" |wc -l);$(cat /proc/sys/net/core/somaxconn);$(netstat -s|grep "failed conn"|cut -d" " -f5);$(netstat -s|grep "overflowed"|cut -d" " -f5);$(cat /etc/krb5.conf|grep dns_lookup_kdc|cut -d"=" -f2);$(ifconfig |grep dropped|grep -v "dropped:0"|cut -d" " -f 14|tr "\n" ",");$(netstat -an|grep WAIT|wc -l);$(netstat -an|grep ESTA|wc -l);$(grep nameserver /etc/resolv.conf|tr "\n" " ");" ' 2>/dev/null; done >> hosts_check



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

