#!/bin/bash

# Check if dns_servers.txt exists
if [ ! -f dns_servers.txt ]; then
    echo "Error: dns_servers.txt not found!"
    exit 1
fi

echo "Testing DNS latency (10s max)..."
echo "---------------------------------------------------------------------------------"
printf "%-20s %-25s %-20s\n" "DNS Server" "Response Time (ms)" "Total Request Time (ms)"
echo "---------------------------------------------------------------------------------"

TEST_DOMAIN="download.docker.com"

# Define the default DNS servers (Add your default DNS here)
DEFAULT_DNS=("8.8.8.8" "8.8.4.4")  # Replace with your default DNS servers

# Create a temporary file for results
RESULTS_FILE=$(mktemp)

# Function to test a DNS server
test_dns() {
    local DNS_SERVER=$1
    START_TIME=$(date +%s%3N)  # Start time in milliseconds
    local RESPONSE_TIME=$(dig @$DNS_SERVER $TEST_DOMAIN +stats +time=10 | awk '/Query time:/ {print $4}')
    END_TIME=$(date +%s%3N)  # End time in milliseconds

    TOTAL_TIME=$((END_TIME - START_TIME))  # Total request time

    if [[ -z "$RESPONSE_TIME" ]]; then
        RESPONSE_TIME="Timeout"
    fi
    if [[ "$RESPONSE_TIME" == "Timeout" ]]; then
        printf "%-20s %-25s %-20s\n" "$DNS_SERVER" "$RESPONSE_TIME" "N/A" >> "$RESULTS_FILE"
    else
        printf "%-20s %-25s %-20s\n" "$DNS_SERVER" "$RESPONSE_TIME" "$TOTAL_TIME" >> "$RESULTS_FILE"
    fi
}

# Run tests in parallel
while read -r DNS_SERVER; do
    if [[ -n "$DNS_SERVER" ]]; then
        test_dns "$DNS_SERVER" &
    fi
done < dns_servers.txt

# Wait for all background processes to finish (max 10s)
sleep 10
wait

# Display results from the file
echo "---------------------------------------------------------------------------------"
cat "$RESULTS_FILE"

# Determine best response time
BEST_SERVER=""
BEST_RESPONSE_TIME=9999
while read -r line; do
    RESPONSE_TIME=$(echo $line | awk '{print $2}')
    DNS_SERVER=$(echo $line | awk '{print $1}')

    if [[ "$RESPONSE_TIME" != "Timeout" ]] && (( RESPONSE_TIME < BEST_RESPONSE_TIME )); then
        BEST_RESPONSE_TIME=$RESPONSE_TIME
        BEST_SERVER=$DNS_SERVER
    fi
done < "$RESULTS_FILE"

echo "---------------------------------------------------------------------------------"
echo "Best DNS Server: $BEST_SERVER with response time: $BEST_RESPONSE_TIME ms"

# Get the current active connection name
CURRENT_CONNECTION=$(nmcli -t -f NAME,TYPE,STATE con show --active | grep -i 'ethernet' | awk -F: '{print $1}' | head -n 1)

# Check if we have a valid connection
if [ -z "$CURRENT_CONNECTION" ]; then
    echo "Error: No active Ethernet connection found."
    exit 1
fi

# Check if any DNS server has a response time less than 150 milliseconds
if [[ -z "$BEST_SERVER" ]] || (( BEST_RESPONSE_TIME >= 150 )); then
    echo "All DNS servers responded with high latency. Reverting to default DNS."
    nmcli con mod "$CURRENT_CONNECTION" ipv4.dns "${DEFAULT_DNS[*]}"  # Set default DNS
else
    echo "Setting $BEST_SERVER as the DNS for $CURRENT_CONNECTION..."
    nmcli con mod "$CURRENT_CONNECTION" ipv4.dns "$BEST_SERVER"  # Set best DNS
fi

# Apply changes
nmcli con up "$CURRENT_CONNECTION"  # Restart connection to apply new DNS settings

echo "DNS configuration updated for $CURRENT_CONNECTION."
echo "---------------------------------------------------------------------------------"
