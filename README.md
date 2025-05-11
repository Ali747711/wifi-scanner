# WiFi Scanner and Device Manager

This is an educational tool for learning about network security and ethical hacking concepts. The script allows you to scan your connected WiFi network for devices and practice network security techniques.

## ⚠️ Important Ethical and Legal Notice

This tool is provided **STRICTLY FOR EDUCATIONAL PURPOSES ONLY**. Using this tool on networks without explicit permission is:

- Potentially **ILLEGAL** in most jurisdictions
- **UNETHICAL** and violates privacy expectations
- May violate terms of service with your internet provider

**ONLY use this tool on networks you own or have explicit permission to test.**

## Prerequisites

The script requires the following tools which it will attempt to install if missing:
- arp-scan
- nmap
- aircrack-ng

## Usage

1. Make the script executable:
   ```
   chmod +x wifi_scanner.sh
   ```

2. Run the script with sudo privileges:
   ```
   sudo ./wifi_scanner.sh
   ```

3. Follow the on-screen menu:
   - Option 1: Scan network for connected devices
   - Option 2: Disconnect a specific device (for educational purposes)
   - Option 3: Exit

## How It Works

The script uses standard networking tools to:
1. Identify your active WiFi interface
2. Scan the local network using ARP requests
3. Demonstrate how deauthentication packets work in WiFi networks

## Learning Objectives

- Understanding network scanning techniques
- Learning about ARP and MAC addresses
- Understanding WiFi deauthentication mechanisms
- Practicing responsible security testing

## Responsible Use

Always remember:
- Only test on your own networks
- Document your activities for educational purposes
- Obtain proper authorization before any security testing
- Consider pursuing formal ethical hacking certifications for professional development
