#!/bin/bash

# =====================================================
# VM-Compatible Wi-Fi Network Scanner and Toolkit
# For educational and authorized penetration testing only
# Created: $(date)
# Designed for virtualized environments without direct wireless adapter access
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
NETWORK_INTERFACE=""
TARGET_IP=""
GATEWAY_IP=""

# Banner
show_banner() {
    clear
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                                                               ║${NC}"
    echo -e "${BLUE}║${GREEN}    VM-Compatible Network Scanner and Security Toolkit     ${BLUE}║${NC}"
    echo -e "${BLUE}║${YELLOW}       For Educational and Authorized Testing Only         ${BLUE}║${NC}"
    echo -e "${BLUE}║                                                               ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${YELLOW}Running in VM Mode: Limited functionality due to virtualized environment${NC}"
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
    local tools=("nmap" "arp-scan" "tcpdump" "python3" "pip3")
    local python_modules=("scapy")
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
        if ! python3 -c "import $module" &> /dev/null 2>&1; then
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
}

# Clean up on exit
cleanup() {
    echo -e "\n${BLUE}Cleaning up...${NC}"
    
    # Remove temporary files
    rm -rf "$TEMP_DIR"
    
    echo -e "${GREEN}Cleanup complete. Exiting.${NC}"
    exit 0
}

# Set up trap to ensure cleanup on exit
trap cleanup EXIT INT TERM

# Get available network interfaces
get_network_interfaces() {
    local interfaces=()
    local ifaces=$(ip -o link show | awk -F': ' '{print $2}' | grep -v "lo")
    
    for iface in $ifaces; do
        # Check if interface has an IP address
        if ip addr show "$iface" | grep -q "inet "; then
            interfaces+=("$iface")
        fi
    done
    
    echo "${interfaces[@]}"
}

# Scan local network
scan_network() {
    local interface=$1
    local subnet
    
    # Get IP and subnet information
    local ip_info=$(ip -4 addr show "$interface" | grep -oP '(?<=inet\s)\d+(\.\d+){3}/\d+')
    local gateway=$(ip route | grep default | grep "$interface" | awk '{print $3}')
    
    if [ -z "$ip_info" ]; then
        echo -e "${RED}Could not determine IP information for $interface.${NC}"
        return 1
    fi
    
    # Extract subnet in CIDR notation
    subnet=$(echo "$ip_info" | cut -d' ' -f1)
    
    echo -e "${BLUE}Interface: $interface${NC}"
    echo -e "${BLUE}IP: $ip_info${NC}"
    echo -e "${BLUE}Gateway: $gateway${NC}"
    echo
    
    GATEWAY_IP="$gateway"
    
    echo -e "${GREEN}Scanning network for connected devices...${NC}"
    echo -e "${YELLOW}This may take a few moments.${NC}"
    
    # Use nmap for network scanning
    nmap -sn "$subnet" -oN "$TEMP_DIR/nmap_scan.txt"
    
    # Process nmap output to extract hosts
    grep "Nmap scan report for" "$TEMP_DIR/nmap_scan.txt" | awk '{print $5 " " $6}' > "$TEMP_DIR/hosts.txt"
    
    # Count hosts found
    local host_count=$(wc -l < "$TEMP_DIR/hosts.txt")
    echo -e "${GREEN}Found $host_count devices on the network.${NC}"
    
    # Show ARP table
    echo -e "\n${BLUE}Current ARP Table:${NC}"
    arp -a
}

# Display hosts in a menu
display_host_menu() {
    local i=1
    local host_array=()
    
    echo -e "\n${BLUE}=== Devices on Network ===${NC}"
    echo -e "${PURPLE}ID\tIP Address\t\tHostname${NC}"
    
    while read -r line; do
        # Parse IP and hostname if available
        local ip=$(echo "$line" | awk '{print $1}')
        local hostname=$(echo "$line" | awk '{$1=""; print $0}' | sed 's/^[ \t]*//')
        
        # If no hostname, use IP
        if [ -z "$hostname" ]; then
            hostname="(unknown)"
        fi
        
        # Store in array for selection
        host_array+=("$ip")
        
        # Display with formatting
        printf "${GREEN}%2d\t${NC}%-15s\t%s\n" "$i" "$ip" "$hostname"
        
        i=$((i+1))
    done < "$TEMP_DIR/hosts.txt"
    
    # Select a host
    echo
    echo -n -e "${YELLOW}Select a target device (1-$((i-1))): ${NC}"
    read -r host_choice
    
    # Validate choice
    if ! [[ "$host_choice" =~ ^[0-9]+$ ]] || [ "$host_choice" -lt 1 ] || [ "$host_choice" -ge "$i" ]; then
        echo -e "${RED}Invalid choice.${NC}"
        return 1
    fi
    
    # Extract selected host IP
    TARGET_IP="${host_array[$((host_choice-1))]}"
    
    echo -e "${GREEN}Selected target: $TARGET_IP${NC}"
    return 0
}

# Perform port scan on target
perform_port_scan() {
    local target=$1
    local scan_type
    
    echo -e "${BLUE}Select scan type:${NC}"
    echo -e "${GREEN}1. Quick scan (top ports)${NC}"
    echo -e "${GREEN}2. Full scan (all ports)${NC}"
    echo -e "${GREEN}3. Service detection${NC}"
    echo -e "${GREEN}4. OS detection${NC}"
    echo -n -e "${YELLOW}Enter your choice [1-4]: ${NC}"
    read -r scan_choice
    
    case $scan_choice in
        1)
            echo -e "${YELLOW}Performing quick scan on $target...${NC}"
            nmap -F -T4 "$target" -oN "$TEMP_DIR/port_scan.txt"
            ;;
        2)
            echo -e "${YELLOW}Performing full port scan on $target...${NC}"
            nmap -p- -T4 "$target" -oN "$TEMP_DIR/port_scan.txt"
            ;;
        3)
            echo -e "${YELLOW}Performing service detection on $target...${NC}"
            nmap -sV -T4 "$target" -oN "$TEMP_DIR/port_scan.txt"
            ;;
        4)
            echo -e "${YELLOW}Performing OS detection on $target...${NC}"
            nmap -O -T4 "$target" -oN "$TEMP_DIR/port_scan.txt"
            ;;
        *)
            echo -e "${RED}Invalid choice. Performing quick scan.${NC}"
            nmap -F -T4 "$target" -oN "$TEMP_DIR/port_scan.txt"
            ;;
    esac
    
    # Display results
    cat "$TEMP_DIR/port_scan.txt"
}

# Monitor network traffic
monitor_network_traffic() {
    local interface=$1
    local target=$2
    local duration
    
    echo -n -e "${YELLOW}Enter monitoring duration in seconds (0 for continuous until Ctrl+C): ${NC}"
    read -r duration
    
    # Validate input
    if ! [[ "$duration" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Invalid input. Using default (30 seconds).${NC}"
        duration=30
    fi
    
    echo -e "${YELLOW}Monitoring network traffic for $target...${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop.${NC}"
    
    if [ "$duration" -eq 0 ]; then
        # Continuous monitoring
        tcpdump -i "$interface" host "$target" -n
    else
        # Fixed duration
        timeout "$duration" tcpdump -i "$interface" host "$target" -n
    fi
}

# Create a simple Python script for ARP spoofing simulation
create_arp_spoof_script() {
    cat > "$TEMP_DIR/arp_spoof_sim.py" << 'EOF'
#!/usr/bin/env python3
# ARP Spoofing Simulation Script
# For educational purposes only

import time
import argparse
from scapy.all import ARP, Ether, srp, send
import sys
import signal

def get_mac(ip, interface):
    """Get MAC address of an IP"""
    try:
        arp = ARP(pdst=ip)
        ether = Ether(dst="ff:ff:ff:ff:ff:ff")
        packet = ether/arp
        result = srp(packet, timeout=3, verbose=0, iface=interface)[0]
        return result[0][1].hwsrc
    except:
        print(f"[!] Could not get MAC address for {ip}")
        return None

def spoof_simulation(target_ip, gateway_ip, interface):
    """Simulate ARP spoofing without actually poisoning the cache"""
    print(f"[*] Starting ARP spoof simulation...")
    print(f"[*] Target: {target_ip}")
    print(f"[*] Gateway: {gateway_ip}")
    print(f"[*] Interface: {interface}")
    
    try:
        target_mac = get_mac(target_ip, interface)
        gateway_mac = get_mac(gateway_ip, interface)
        
        if not target_mac or not gateway_mac:
            print("[!] Could not get MAC addresses. Exiting.")
            return
        
        print(f"[*] Target MAC: {target_mac}")
        print(f"[*] Gateway MAC: {gateway_mac}")
        print("\n[*] In a real attack, ARP cache would be poisoned now")
        print("[*] SIMULATION ONLY - No actual ARP poisoning is occurring")
        
        # Create sample packets that would be used (but don't send them)
        target_packet = ARP(op=2, pdst=target_ip, hwdst=target_mac, psrc=gateway_ip)
        gateway_packet = ARP(op=2, pdst=gateway_ip, hwdst=gateway_mac, psrc=target_ip)
        
        print("\n[*] Packets that would be sent in a real attack:")
        print(f"[*] To target: {target_packet.summary()}")
        print(f"[*] To gateway: {gateway_packet.summary()}")
        
        count = 0
        try:
            while True:
                count += 1
                print(f"\r[*] Simulation packets: {count}", end="")
                time.sleep(1)
        except KeyboardInterrupt:
            print("\n[*] Stopping simulation...")
            
    except Exception as e:
        print(f"[!] Error: {e}")

def main():
    parser = argparse.ArgumentParser(description='ARP Spoofing Simulation')
    parser.add_argument('target', help='Target IP address')
    parser.add_argument('gateway', help='Gateway IP address')
    parser.add_argument('interface', help='Network interface')
    
    args = parser.parse_args()
    
    try:
        spoof_simulation(args.target, args.gateway, args.interface)
    except KeyboardInterrupt:
        print("\n[*] Simulation stopped by user")
        sys.exit(0)

if __name__ == "__main__":
    main()
EOF

    chmod +x "$TEMP_DIR/arp_spoof_sim.py"
}

# Simulate ARP spoofing attack
simulate_arp_spoofing() {
    local interface=$1
    local target=$2
    local gateway=$3
    
    if [ -z "$target" ] || [ -z "$gateway" ]; then
        echo -e "${RED}Target or gateway IP not specified.${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Starting ARP spoofing simulation...${NC}"
    echo -e "${RED}NOTE: This is only a simulation. No actual ARP poisoning will occur.${NC}"
    
    # Create the simulation script if it doesn't exist
    if [ ! -f "$TEMP_DIR/arp_spoof_sim.py" ]; then
        create_arp_spoof_script
    fi
    
    # Run the simulation
    python3 "$TEMP_DIR/arp_spoof_sim.py" "$target" "$gateway" "$interface"
}

# Create a simple Python script for DoS simulation
create_dos_sim_script() {
    cat > "$TEMP_DIR/dos_sim.py" << 'EOF'
#!/usr/bin/env python3
# DoS Attack Simulation Script
# For educational purposes only

import time
import argparse
import sys
import random
from scapy.all import IP, TCP, send

def simulate_dos(target_ip, target_port, duration):
    """Simulate a DoS attack without actually sending packets"""
    print(f"[*] Starting DoS attack simulation against {target_ip}:{target_port}")
    print(f"[*] Duration: {duration} seconds")
    print("[*] SIMULATION ONLY - No actual packets are being sent")
    
    start_time = time.time()
    packet_count = 0
    
    try:
        while True:
            current_time = time.time()
            elapsed = current_time - start_time
            
            if duration > 0 and elapsed > duration:
                break
                
            # Simulate packet creation (but don't send)
            source_port = random.randint(1024, 65535)
            sequence = random.randint(1000000000, 2000000000)
            
            # Create a sample packet
            packet = IP(dst=target_ip)/TCP(sport=source_port, dport=target_port, seq=sequence, flags="S")
            
            packet_count += 1
            
            # Print progress
            if packet_count % 100 == 0:
                print(f"\r[*] Simulated packets: {packet_count} | Elapsed time: {elapsed:.2f}s", end="")
                
            # Throttle the loop to not consume too much CPU
            time.sleep(0.01)
            
    except KeyboardInterrupt:
        pass
        
    print(f"\n[*] Simulation complete. {packet_count} packets simulated over {elapsed:.2f} seconds")
    print("[*] In a real attack, this could potentially disrupt the target service")

def main():
    parser = argparse.ArgumentParser(description='DoS Attack Simulation')
    parser.add_argument('target', help='Target IP address')
    parser.add_argument('port', type=int, help='Target port')
    parser.add_argument('--duration', type=int, default=10, help='Simulation duration in seconds (0 for continuous)')
    
    args = parser.parse_args()
    
    try:
        simulate_dos(args.target, args.port, args.duration)
    except KeyboardInterrupt:
        print("\n[*] Simulation stopped by user")
        sys.exit(0)

if __name__ == "__main__":
    main()
EOF

    chmod +x "$TEMP_DIR/dos_sim.py"
}

# Simulate DoS attack
simulate_dos_attack() {
    local target=$1
    local port
    local duration
    
    if [ -z "$target" ]; then
        echo -e "${RED}Target IP not specified.${NC}"
        return 1
    fi
    
    echo -n -e "${YELLOW}Enter target port: ${NC}"
    read -r port
    
    # Validate port
    if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        echo -e "${RED}Invalid port. Using default (80).${NC}"
        port=80
    fi
    
    echo -n -e "${YELLOW}Enter simulation duration in seconds (0 for continuous until Ctrl+C): ${NC}"
    read -r duration
    
    # Validate duration
    if ! [[ "$duration" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Invalid duration. Using default (10 seconds).${NC}"
        duration=10
    fi
    
    echo -e "${YELLOW}Starting DoS attack simulation...${NC}"
    echo -e "${RED}NOTE: This is only a simulation. No actual attack traffic will be generated.${NC}"
    
    # Create the simulation script if it doesn't exist
    if [ ! -f "$TEMP_DIR/dos_sim.py" ]; then
        create_dos_sim_script
    fi
    
    # Run the simulation
    python3 "$TEMP_DIR/dos_sim.py" "$target" "$port" --duration "$duration"
}

# Main menu
show_main_menu() {
    echo -e "${BLUE}===== VM-Compatible Network Toolkit =====${NC}"
    echo -e "${GREEN}1. Select network interface${NC}"
    echo -e "${GREEN}2. Scan local network${NC}"
    echo -e "${GREEN}3. Perform port scan on target${NC}"
    echo -e "${GREEN}4. Monitor network traffic${NC}"
    echo -e "${GREEN}5. Simulate ARP spoofing (educational)${NC}"
    echo -e "${GREEN}6. Simulate DoS attack (educational)${NC}"
    echo -e "${RED}7. Exit${NC}"
    echo
    echo -n -e "${YELLOW}Enter your choice [1-7]: ${NC}"
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
                # Select network interface
                interfaces=($(get_network_interfaces))
                interface_count=${#interfaces[@]}
                
                if [ "$interface_count" -eq 0 ]; then
                    echo -e "${RED}No network interfaces found.${NC}"
                    continue
                fi
                
                echo -e "${BLUE}Available network interfaces:${NC}"
                for ((i=0; i<interface_count; i++)); do
                    echo -e "${GREEN}$((i+1)). ${interfaces[$i]}${NC}"
                done
                
                echo -n -e "${YELLOW}Select interface [1-$interface_count]: ${NC}"
                read -r interface_choice
                
                if ! [[ "$interface_choice" =~ ^[0-9]+$ ]] || [ "$interface_choice" -lt 1 ] || [ "$interface_choice" -gt "$interface_count" ]; then
                    echo -e "${RED}Invalid choice.${NC}"
                    continue
                fi
                
                NETWORK_INTERFACE="${interfaces[$((interface_choice-1))]}"
                echo -e "${GREEN}Selected interface: $NETWORK_INTERFACE${NC}"
                ;;
            2)
                # Scan local network
                if [ -z "$NETWORK_INTERFACE" ]; then
                    echo -e "${RED}Please select a network interface first.${NC}"
                    continue
                fi
                
                scan_network "$NETWORK_INTERFACE" && display_host_menu
                ;;
            3)
                # Perform port scan
                if [ -z "$TARGET_IP" ]; then
                    echo -e "${RED}Please select a target device first.${NC}"
                    continue
                fi
                
                perform_port_scan "$TARGET_IP"
                ;;
            4)
                # Monitor network traffic
                if [ -z "$NETWORK_INTERFACE" ] || [ -z "$TARGET_IP" ]; then
                    echo -e "${RED}Please select a network interface and target device first.${NC}"
                    continue
                fi
                
                monitor_network_traffic "$NETWORK_INTERFACE" "$TARGET_IP"
                ;;
            5)
                # Simulate ARP spoofing
                if [ -z "$NETWORK_INTERFACE" ] || [ -z "$TARGET_IP" ] || [ -z "$GATEWAY_IP" ]; then
                    echo -e "${RED}Please select a network interface and scan the network first.${NC}"
                    continue
                fi
                
                simulate_arp_spoofing "$NETWORK_INTERFACE" "$TARGET_IP" "$GATEWAY_IP"
                ;;
            6)
                # Simulate DoS attack
                if [ -z "$TARGET_IP" ]; then
                    echo -e "${RED}Please select a target device first.${NC}"
                    continue
                fi
                
                simulate_dos_attack "$TARGET_IP"
                ;;
            7)
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
