# DNS Latency Test Script

This script allows you to test the latency of multiple DNS servers by measuring their response times for a specific domain. It reads DNS server IPs from a text file (`dns_servers.txt`), tests them using the `dig` command, and outputs the results in a human-readable format. The script now includes more robust error handling, DNS server validation, and automatic updates of the system's DNS settings.


## Features

- Tests DNS latency for multiple servers in parallel (up to 50 concurrent requests).
- Displays response times in milliseconds (ms) for each DNS server.
- Sorts and displays results by response time (fastest to slowest).
- Automatically updates DNS settings for the active network connection based on the fastest server (if latency is under 150ms).
- Validates DNS server IP addresses to ensure they are properly formatted.
- Handles errors gracefully and provides helpful messages for invalid DNS servers or network issues.
- Supports Linux-based systems with NetworkManager and nmcli available.


## Prerequisites

- Linux-based OS (Ubuntu, Rocky Linux, etc.)
- `dig` command installed (usually part of the `dnsutils` package).
- `nmcli` tool available (part of NetworkManager).

## Setup Instructions

1. **Clone the repository:**
   ```bash
   git clone https://github.com/netamirbabaei/DNS-Test-Speed.git
   cd DNS-Test-Speed/
   ```
   
2. Modify the dns_servers.txt file: Open the dns_servers.txt file and add the DNS servers you want to test (one per line). Example:
   ```bash
   185.51.200.2
   78.157.42.101
   5.202.100.101
   5.202.100.100
   ```
  
3. Run the script:
   ```bash
   sudo ./dns_speed_test_parallel.sh
   ```
   
   The script will:
   - Test each DNS server.
   - Display response times for each DNS server.
   - Sort and display the results by latency.
   - Automatically update the system's DNS settings based on the fastest server (if it's under 150ms latency).

4. View the results:
   The script will output DNS server response times, sorted from fastest to slowest. The best DNS server will be selected, and your system’s DNS configuration will be updated accordingly.

### Example Output
   ```bash
   ---------------------------------------------------------------------------------
   DNS Server           Response Time (ms)        Total Request Time (ms)
   ---------------------------------------------------------------------------------
   185.51.200.2         51                        88                  
   78.157.42.101        64                        98                  
   5.202.100.101        60                        91                  
   5.202.100.100        68                        99                  
   78.157.42.100        67                        101                 
   185.55.226.26        125                       170                 
   10.202.10.10         129                       172                 
   10.202.10.11         175                       223                 
   178.22.122.100       1263                      11319               
   10.202.10.202        Timeout                   N/A                 
   10.202.10.102        Timeout                   N/A                 
   185.55.225.25        Timeout                   N/A                 
   ---------------------------------------------------------------------------------
   Best DNS Server: 185.51.200.2 with response time: 51 ms
   Setting 185.51.200.2 as the DNS for Wired connection 1...
   Connection successfully activated (D-Bus active path: /org/freedesktop/NetworkManager/ActiveConnection/29)
   DNS configuration updated for Wired connection 1.
   ---------------------------------------------------------------------------------
   ```
## Customization

- Modify Default DNS Servers: You can change the default DNS servers in the script by updating the DEFAULT_DNS array.
- Change Test Domain: The script currently tests DNS servers with the domain download.docker.com. You can change the domain by modifying the TEST_DOMAIN variable in the script.

## Troubleshooting

- Missing `dig` Command: If the dig command is not found, you can install it with:

  ```bash
  sudo apt install dnsutils  # Ubuntu/Debian
  sudo yum install bind-utils  # CentOS/RHEL
  ```
  
- No Active Ethernet Connection: If the script cannot find an active Ethernet connection, ensure that you have a valid network connection and that nmcli is available.

