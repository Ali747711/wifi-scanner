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

# Check for required tools and install if possible
check_requirements() {
    # Check for Homebrew
    if ! command -v brew &> /dev/null; then
        echo -e "${YELLOW}Homebrew is not installed. It's required to install dependencies.${NC}"
        echo -e "${BLUE}Would you like to install Homebrew? (y/n)${NC}"
        read -r answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        else
            echo -e "${RED}Cannot proceed without Homebrew. Exiting.${NC}"
            exit 1
        fi
    fi
    
    # Check for required tools
    local tools=("nmap")
    local missing=()
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing+=("$tool")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        echo -e "${YELLOW}Missing required tools: ${missing[*]}${NC}"
        echo -e "${BLUE}Installing missing tools...${NC}"
        for tool in "${missing[@]}"; do
            brew install "$tool"
        done
    fi
}

# Get current WiFi interface on macOS
get_wifi_interface() {
    # Find the active WiFi interface on macOS
    local interface=$(networksetup -listallhardwareports | grep -A 1 "Wi-Fi" | grep "Device" | awk '{print $2}')
    
    if [ -z "$interface" ]; then
        echo -e "${RED}No wireless interface found.${NC}"
        exit 1
    fi
    
    echo "$interface"
}

# Scan for connected devices on macOS
scan_network() {
    local interface=$1
    local gateway=$(netstat -nr | grep default | head -n 1 | awk '{print $2}')
    local subnet=$(ifconfig "$interface" | grep "inet " | awk '{print $2"/24"}' | head -n 1)
    
    echo -e "${BLUE}Interface: $interface${NC}"
    echo -e "${BLUE}Gateway: $gateway${NC}"
    echo -e "${BLUE}Subnet: $subnet${NC}"
    echo
    
    echo -e "${GREEN}Scanning network for connected devices...${NC}"
    echo -e "${YELLOW}This may take a few moments.${NC}"
    
    # Use nmap for network scanning on macOS
    sudo nmap -sn "$subnet"
    
    # Show current ARP table
    echo -e "\n${BLUE}Current ARP Table:${NC}"
    arp -a
}

# Get MAC address of a device by IP on macOS
get_mac_by_ip() {
    local ip=$1
    local mac=$(arp -a | grep "$ip" | awk '{print $4}')
    echo "$mac"
}

# Disconnect a device from the network on macOS
# Note: This is a simplified version for educational purposes
disconnect_device() {
    local interface=$1
    local target_ip=$2
    local target_mac=$(get_mac_by_ip "$target_ip")
    
    if [ -z "$target_mac" ]; then
        echo -e "${RED}Could not find MAC address for IP: $target_ip${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Target device: $target_ip (MAC: $target_mac)${NC}"
    echo -e "${BLUE}On macOS, actual disconnection requires additional tools.${NC}"
    echo -e "${BLUE}For educational purposes, here's what would happen:${NC}"
    echo -e "${GREEN}1. Put interface in monitor mode${NC}"
    echo -e "${GREEN}2. Send deauthentication packets to target${NC}"
    echo -e "${GREEN}3. Return interface to managed mode${NC}"
    
    # For actual implementation, you would need to install additional tools
    echo -e "\n${YELLOW}To implement actual disconnection functionality:${NC}"
    echo -e "${BLUE}1. Install aircrack-ng: brew install aircrack-ng${NC}"
    echo -e "${BLUE}2. Use airmon-ng and aireplay-ng commands${NC}"
    
    echo -e "\n${GREEN}Simulation completed.${NC}"
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
