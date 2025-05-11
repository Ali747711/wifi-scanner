# Advanced Wi-Fi Network Scanner and Targeted Disconnector

This advanced toolkit is designed for educational purposes and authorized penetration testing on Linux-based systems. It provides a comprehensive set of features for WiFi network analysis and security testing.

## ⚠️ IMPORTANT LEGAL AND ETHICAL NOTICE ⚠️

This tool is provided **STRICTLY FOR EDUCATIONAL AND AUTHORIZED TESTING PURPOSES ONLY**. 

Using this tool on networks without explicit permission is:
- **ILLEGAL** in most jurisdictions
- A violation of the Computer Fraud and Abuse Act (in the US) and similar laws worldwide
- **UNETHICAL** and violates privacy expectations
- May violate terms of service with your internet provider

**ONLY use this tool on networks you own or have explicit written permission to test.**

## Features

- **Interface Management**
  - Detect available wireless interfaces
  - Enable monitor mode on selected interfaces

- **Network Scanning**
  - Scan for nearby Wi-Fi access points
  - Display detailed AP information (SSID, BSSID, Channel, Signal Strength)

- **Client Tracking**
  - Identify devices connected to a selected access point
  - Display client information (MAC address, signal strength, data packets)

- **Selective Deauthentication**
  - Target specific clients or all clients on a network
  - Configure continuous or burst mode attacks
  - Educational demonstration of WiFi vulnerabilities

## Prerequisites

- A Linux-based operating system
- A wireless adapter capable of monitor mode and packet injection
- Root/sudo privileges
- The following dependencies (automatically installed by the script):
  - aircrack-ng suite (airmon-ng, airodump-ng, aireplay-ng)
  - Python 3 with scapy and rich modules

## Usage

1. Make the script executable:
   ```
   chmod +x advanced_wifi_toolkit.sh
   ```

2. Run the script with sudo privileges:
   ```
   sudo ./advanced_wifi_toolkit.sh
   ```

3. Follow the interactive menu:
   - Select a wireless interface
   - Scan for access points
   - Select an access point to monitor
   - Scan for connected clients
   - Perform educational deauthentication tests

## How It Works

The script leverages standard Linux networking tools and the aircrack-ng suite to:

1. Put wireless interfaces into monitor mode
2. Capture and analyze 802.11 frames
3. Identify access points and connected clients
4. Demonstrate how deauthentication attacks work

## Educational Value

This toolkit helps security professionals and students understand:
- WiFi network reconnaissance techniques
- Client-AP relationships and authentication mechanisms
- Common WiFi vulnerabilities
- Network security assessment methodologies

## Responsible Use Guidelines

- Always obtain written permission before testing any network
- Document all testing activities
- Limit the scope and impact of your tests
- Report findings responsibly to network owners
- Consider pursuing formal ethical hacking certifications
