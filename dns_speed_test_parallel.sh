#!/bin/bash

set -euo pipefail # Enable strict error handling

# Define possible DNS list file locations
SYSTEM_DNS_FILE="/etc/dns_test_speed/dns_servers.txt"
LOCAL_DNS_FILE="./dns_servers.txt"

# Check priority: system-wide config first, then local file
if [ -f "$SYSTEM_DNS_FILE" ]; then
  DNS_FILE="$SYSTEM_DNS_FILE"
elif [ -f "$LOCAL_DNS_FILE" ]; then
  DNS_FILE="$LOCAL_DNS_FILE"
else
  echo "Error: No dns_servers.txt found in /etc/dns_test_speed/ or current directory."
  exit 1
fi

# Function to show all DNS servers stored in dns_servers.txt
show_ips() {
  echo "Current DNS servers in $DNS_FILE:"
  cat "$DNS_FILE"
}

# Function to add one or more DNS servers to dns_servers.txt
add_ips() {
  for ip in "$@"; do # Loop over all IPs given as arguments
    # Check if IP already exists in the file
    if ! grep -q "^$ip$" "$DNS_FILE"; then
      echo "$ip" >>"$DNS_FILE" # Append new IP to the file
      echo "Added: $ip"
    else
      echo "Already exists: $ip" # Skip duplicates
    fi
  done
}

# Function to remove one or more DNS servers from dns_servers.txt
remove_ips() {
  for ip in "$@"; do # Loop over all IPs given as arguments
    # Check if the IP exists in the file
    if grep -q "^$ip$" "$DNS_FILE"; then
      sed -i "/^$ip$/d" "$DNS_FILE" # Delete the matching line
      echo "Removed: $ip"
    else
      echo "Not found: $ip" # Inform if IP is missing
    fi
  done
}

# Function to test a DNS server
test_dns() {
  local DNS_SERVER=$1
  START_TIME=$(date +%s%3N) # Start time in milliseconds
  local RESPONSE_TIME=$(dig @$DNS_SERVER $TEST_DOMAIN +stats +time=10 | awk '/Query time:/ {print $4}')
  END_TIME=$(date +%s%3N) # End time in milliseconds

  TOTAL_TIME=$((END_TIME - START_TIME)) # Total request time

  if [[ -z "$RESPONSE_TIME" ]]; then
    RESPONSE_TIME="Timeout"
  fi
  if [[ "$RESPONSE_TIME" == "Timeout" ]]; then
    printf "%-20s %-25s %-20s\n" "$DNS_SERVER" "$RESPONSE_TIME" "N/A" >>"$RESULTS_FILE"
  else
    printf "%-20s %-25s %-20s\n" "$DNS_SERVER" "$RESPONSE_TIME" "$TOTAL_TIME" >>"$RESULTS_FILE"
  fi
}

run_tests_and_set() {
  TEST_DOMAIN=$1

  # Define the default DNS servers (Add your default DNS here)
  DEFAULT_DNS=("8.8.8.8" "8.8.4.4") # Replace with your default DNS servers

  # Create a temporary file for results
  RESULTS_FILE=$(mktemp)

  echo "Testing DNS latency (10s max)..."
  echo "---------------------------------------------------------------------------------"
  printf "%-20s %-25s %-20s\n" "DNS Server" "Response Time (ms)" "Total Request Time (ms)"
  echo "---------------------------------------------------------------------------------"

  # Run tests in parallel
  while read -r DNS_SERVER; do
    if [[ -n "$DNS_SERVER" && "$DNS_SERVER" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      test_dns "$DNS_SERVER" &
    else
      echo "Warning: Invalid DNS server $DNS_SERVER, skipping."
    fi
  done <$DNS_FILE

  # Wait for all background processes to finish (max 10s)
  sleep 10
  wait

  # Display results from the file
  cat "$RESULTS_FILE"

  # Determine best response time
  BEST_SERVER=""
  BEST_RESPONSE_TIME=9999
  while read -r line; do
    RESPONSE_TIME=$(echo $line | awk '{print $2}')
    DNS_SERVER=$(echo $line | awk '{print $1}')

    if [[ "$RESPONSE_TIME" != "Timeout" ]] && ((RESPONSE_TIME < BEST_RESPONSE_TIME)); then
      BEST_RESPONSE_TIME=$RESPONSE_TIME
      BEST_SERVER=$DNS_SERVER
    fi
  done <"$RESULTS_FILE"
  rm -rf "$RESULTS_FILE"

  echo "---------------------------------------------------------------------------------"
  echo "Best DNS Server: $BEST_SERVER with response time: $BEST_RESPONSE_TIME ms"

  # Get the current active connection name (Ethernet or Wi-Fi)
  CURRENT_CONNECTION=$(nmcli -t -f NAME,TYPE,STATE con show --active | grep -E 'ethernet|wifi|wireless' | awk -F: '{print $1}' | head -n 1)

  # Check if we have a valid connection
  if [ -z "$CURRENT_CONNECTION" ]; then
    echo "Error: No active Ethernet or Wi-Fi connection found."
    exit 1
  fi

  # Check if any DNS server has a response time less than 150 milliseconds
  if [[ -z "$BEST_SERVER" ]] || ((BEST_RESPONSE_TIME >= 150)); then
    echo "All DNS servers responded with high latency. Reverting to default DNS."
    nmcli con mod "$CURRENT_CONNECTION" ipv4.dns "${DEFAULT_DNS[*]}" # Set default DNS
  else
    echo "Setting $BEST_SERVER as the DNS for $CURRENT_CONNECTION..."
    nmcli con mod "$CURRENT_CONNECTION" ipv4.dns "$BEST_SERVER" # Set best DNS
  fi

  # Apply changes
  nmcli con up "$CURRENT_CONNECTION" # Restart connection to apply new DNS settings

  echo "DNS configuration updated for $CURRENT_CONNECTION."
}

# -----------------------------
# Main logic
# -----------------------------
case "${1:-}" in
--show)
  show_ips
  ;;
--add)
  shift
  add_ips "$@"
  ;;
--remove)
  shift
  remove_ips "$@"
  ;;
*)
  run_tests_and_set $1
  ;;
esac
