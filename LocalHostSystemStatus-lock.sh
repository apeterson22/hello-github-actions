#!/bin/bash

# Check if lock file exists
if [ -f /var/run/LocalHostSystemStatus.lock ]; then
  echo "Error: Script is already running."
  exit 1
fi

# Create lock file
touch /var/run/LocalHostSystemStatus.lock

# Define variables
email="$1"
webhook="$2"
threshold=80

# Define functions
function send_email {
  subject="Disk space threshold reached"
  message="The disk space usage has reached ${1}%."
  echo "${message}" | mail -s "${subject}" "${email}"
}

function send_webhook {
  curl -H "Content-Type: application/json" -X POST -d '{"text":"'${1}'"}' "${webhook}"
}

# Get ports status, traffic, IPs, and hostnames
netstat -tulanp > ports.txt

# Get disk statistics, space, and performance
df -h > disks.txt

# Check if disk space usage is over threshold and send notifications
while read line; do
  usage=$(echo "${line}" | awk '{print $5}' | sed 's/%//')
  if [[ "${usage}" -ge "${threshold}" ]]; then
    send_email "${usage}"
    send_webhook "Disk space threshold reached. Usage is ${usage}%."
  fi
done < disks.txt

# Log statistics to file in json format
jq -n --argfile ports ports.txt --argfile disks disks.txt '{ports: $ports, disks: $disks}' > stats.json

# Remove lock file
rm -f /var/run/LocalHostSystemStatus.lock
