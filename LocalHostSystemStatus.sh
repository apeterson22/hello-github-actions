#!/bin/bash

# Get command-line arguments
email_address=$1
teams_webhook_url=$2

# Check all ports
echo "Checking all ports..."

netstat -tunlp | awk '{print $4,$6,$7}' | tail -n +3 | sed -e 's/.*://' | awk '{print $1}' | sort | uniq -c | while read count port; do
    if [ "$count" -gt 0 ]; then
        echo "Port $port: $count connections"
    fi
done

# Check disk statistics
echo "Checking disk statistics..."

df -h | tail -n +2 | while read filesystem size used available percent mountpoint; do
    if [ "${percent%?}" -ge 80 ]; then
        echo "WARNING: Disk space on $mountpoint is $percent full"
        
        # Send email
        echo "Sending email..."
        echo "Disk space on $mountpoint is $percent full" | mail -s "Disk space warning" "$email_address"
        
        # Send Teams webhook
        echo "Sending Teams webhook..."
        json="{\"title\": \"Disk space warning\", \"text\": \"Disk space on $mountpoint is $percent full\"}"
        curl -H "Content-Type: application/json" -d "$json" "$teams_webhook_url"
    fi
done

# Check disk performance
echo "Checking disk performance..."

iostat -dx 1 2 | tail -n +4 | head -n 1 | awk '{print "Disk read rate: " $3 " kB/s, disk write rate: " $4 " kB/s"}'

# Check system load
echo "Checking system load..."

uptime
