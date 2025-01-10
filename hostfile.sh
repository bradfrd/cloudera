#!/bin/bash

# List of hosts to collect information from
HOSTS=(host1 host2 host3 host4 host5 host6)

# Temporary file to store host information
tmp_file="/tmp/hosts_update_$(date +%s)"

# Clear the temporary file
echo "# Generated hosts file - $(date)" > "$tmp_file"

# Collect hostname and IP information from each host
for host in "${HOSTS[@]}"; do
    echo "Connecting to $host to fetch details..."

    # Fetch IP address and hostname details
    ip=$(ssh "$host" "hostname -I | awk '{print \$1}'")
    fqdn=$(ssh "$host" "hostname -f")
    shortname=$(ssh "$host" "hostname -s")

    if [[ -n "$ip" && -n "$fqdn" && -n "$shortname" ]]; then
        echo "$ip $fqdn $shortname" >> "$tmp_file"
    else
        echo "Failed to retrieve information from $host. Skipping..."
    fi

done

# Copy the updated hosts file to each host
for host in "${HOSTS[@]}"; do
    echo "Updating /etc/hosts on $host..."
    scp "$tmp_file" "$host:/tmp/updated_hosts"
    ssh "$host" "cat /tmp/updated_hosts >> /etc/hosts && rm -f /tmp/updated_hosts"
    if [[ $? -eq 0 ]]; then
        echo "/etc/hosts successfully updated on $host."
    else
        echo "Failed to update /etc/hosts on $host."
    fi
done

# Cleanup temporary file
rm -f "$tmp_file"

echo "All hosts have been updated."

