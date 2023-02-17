#!/bin/bash

# Check for dependencies and install if not present
if ! command -v ss &> /dev/null
then
    sudo apt-get update && sudo apt-get install -y iproute2
fi

if ! command -v bc &> /dev/null
then
    sudo apt-get update && sudo apt-get install -y bc
fi

if ! command -v jq &> /dev/null
then
    sudo apt-get update && sudo apt-get install -y jq
fi

# Create a lock file to ensure only one instance of the script runs at a time
LOCKFILE=/tmp/LocalHostSystemStatus.lock
if [ -f "$LOCKFILE" ] && kill -0 "$(cat "$LOCKFILE")"; then
    echo "Script is already running."
    exit
fi
echo $$ > "$LOCKFILE"

# Get system information
PORTS="$(ss -tulwn | awk '{print $1,$4,$5}')"
DISK="$(df -h | awk '$NF=="/"{printf "%d/%d (%s)", $3,$2,$5}')"
MEMORY="$(free | awk '/Mem/{printf("%.2f%"), $3/$2*100}')"
CPU="$(top -bn1 | grep load | awk '{printf "%.2f\n", $(NF-2)}')"
IP="$(hostname -I)"
HOSTNAME="$(hostname)"

# Check disk space usage
DISK_USAGE="$(df -h | awk '$NF=="/"{printf "%d", $5}')"
if [ $DISK_USAGE -ge 80 ]; then
    # Send an email notification
    EMAIL="$1"
    echo "Disk space usage is at $DISK_USAGE%. Sending an email notification to $EMAIL"
    echo "Disk space usage is at $DISK_USAGE% on $HOSTNAME. Please take action." | mail -s "Disk Space Alert on $HOSTNAME" $EMAIL
    
    # Send a MS Teams notification
    WEBHOOK="$2"
    curl -H "Content-Type: application/json" -d "{\"text\": \"Disk space usage is at $DISK_USAGE% on $HOSTNAME. Please take action.\"}" $WEBHOOK
fi

# Log system information to a file in JSON format
LOGFILE=/var/log/LocalHostSystemStatus.log
if [ ! -f "$LOGFILE" ]; then
    touch "$LOGFILE"
    echo "[" >> "$LOGFILE"
else
    sed -i -e '$ d' "$LOGFILE"
    echo "," >> "$LOGFILE"
fi
echo "{ \"timestamp\": \"$(date)\", \"ip\": \"$IP\", \"hostname\": \"$HOSTNAME\", \"ports\": \"$PORTS\", \"disk\": \"$DISK\", \"memory\": \"$MEMORY\", \"cpu\": \"$CPU\" }]" >> "$LOGFILE"

# Remove lock file
trap "rm -f '$LOCKFILE'" EXIT

echo "System status logged to $LOGFILE"
