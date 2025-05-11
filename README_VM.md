# VM-Compatible Network Scanner and Security Toolkit

This toolkit is designed specifically for virtualized environments (like Kali Linux running in UTM on macOS) where direct access to wireless adapters with monitor mode is not available.

## ⚠️ IMPORTANT LEGAL AND ETHICAL NOTICE ⚠️

This tool is provided **STRICTLY FOR EDUCATIONAL AND AUTHORIZED TESTING PURPOSES ONLY**. 

Using this tool on networks without explicit permission is:
- **ILLEGAL** in most jurisdictions
- **UNETHICAL** and violates privacy expectations
- May violate terms of service with your internet provider

**ONLY use this tool on networks you own or have explicit written permission to test.**

## VM-Specific Limitations

When running security tools in a virtualized environment, several limitations exist:

1. **No Monitor Mode**: VMs typically can't access the physical wireless adapter's monitor mode capabilities
2. **No Packet Injection**: Direct packet injection is not possible through the virtualized network interface
3. **Limited Network Access**: The VM only sees the network through its virtualized interface

This toolkit works within these limitations to provide educational value while still demonstrating key network security concepts.

## Features

- **Network Interface Management**
  - Detect available network interfaces in the VM
  - Work with the VM's virtual network adapter

- **Network Scanning**
  - Scan the local network for connected devices
  - Display detailed host information

- **Target Analysis**
  - Perform port scans on selected targets
  - Monitor network traffic to/from specific hosts

- **Educational Simulations**
  - Simulate ARP spoofing attacks (without actual packet injection)
  - Simulate DoS attacks (without generating actual attack traffic)

## Prerequisites

- A Linux-based operating system (like Kali Linux) running in a VM
- Root/sudo privileges
- The following dependencies (automatically installed by the script):
  - nmap
  - arp-scan
  - tcpdump
  - Python 3 with scapy module

## Usage

1. Make the script executable:
   ```
   chmod +x vm_wifi_toolkit.sh
   ```

2. Run the script with sudo privileges:
   ```
   sudo ./vm_wifi_toolkit.sh
   ```

3. Follow the interactive menu:
   - Select a network interface
   - Scan the local network
   - Select target devices
   - Perform port scans
   - Monitor network traffic
   - Run educational simulations

## Educational Value

This toolkit helps security professionals and students understand:
- Network reconnaissance techniques
- Host discovery and enumeration
- Port scanning and service identification
- Traffic monitoring and analysis
- Attack vectors (through simulation only)

## Responsible Use Guidelines

- Always obtain written permission before testing any network
- Document all testing activities
- Limit the scope and impact of your tests
- Report findings responsibly to network owners
