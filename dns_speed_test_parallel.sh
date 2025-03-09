#!/bin/bash

# Check if dns_servers.txt exists
if [ ! -f dns_servers.txt ]; then
    echo "Error: dns_servers.txt not found!"
    exit 1
fi

echo "Testing DNS latency (10s max)..."
echo "-------------------------------------"
echo "DNS Server          Response Time (ms)"
echo "-------------------------------------"

TEST_DOMAIN="download.docker.com"

# Create a temporary file for results
RESULTS_FILE=$(mktemp)

# Function to test a DNS server
test_dns() {
    local DNS_SERVER=$1
    local RESPONSE_TIME=$(dig @$DNS_SERVER $TEST_DOMAIN +stats +time=10 | awk '/Query time:/ {print $4}')
    if [[ -z "$RESPONSE_TIME" ]]; then
        RESPONSE_TIME="Timeout"
    fi
    if [[ "$RESPONSE_TIME" == "Timeout" ]]; then
        printf "%-20s %s\n" "$DNS_SERVER" "$RESPONSE_TIME" >> "$RESULTS_FILE"
    else
        printf "%-20s %s ms\n" "$DNS_SERVER" "$RESPONSE_TIME" >> "$RESULTS_FILE"
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

# Print results
sort -nk2 "$RESULTS_FILE" 2>/dev/null
rm -f "$RESULTS_FILE"

echo "-------------------------------------"

