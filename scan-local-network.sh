#!/bin/bash 
set -euo pipefail

# Script Description: Scans the 192.168.0.0/22 subnet for active hosts and retrieves ARP table entries.
# Author: elvee
# Version: 0.1.0
# License: MIT
# Creation Date: 16-11-2024
# Last Modified: 16-11-2024
# Usage: ./scan-local-network.sh

# Constants
SCAN_SUBNET="192.168.0.0/24"  # Subnet to scan
TAB=$'\t'

# Function to display ASCII art
print_ascii_art() {
  echo "
       
           ██╗      ██████╗  ██████╗ █████╗ ██╗              
           ██║     ██╔═══██╗██╔════╝██╔══██╗██║              
           ██║     ██║   ██║██║     ███████║██║              
           ██║     ██║   ██║██║     ██╔══██║██║              
           ███████╗╚██████╔╝╚██████╗██║  ██║███████╗         
           ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝         
                                                              
███╗   ██╗███████╗████████╗██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗
████╗  ██║██╔════╝╚══██╔══╝██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝
██╔██╗ ██║█████╗     ██║   ██║ █╗ ██║██║   ██║██████╔╝█████╔╝ 
██║╚██╗██║██╔══╝     ██║   ██║███╗██║██║   ██║██╔══██╗██╔═██╗ 
██║ ╚████║███████╗   ██║   ╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗
╚═╝  ╚═══╝╚══════╝   ╚═╝    ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
                                                              
  ███████╗ ██████╗ █████╗ ███╗   ██╗███╗   ██╗███████╗██████╗   
  ██╔════╝██╔════╝██╔══██╗████╗  ██║████╗  ██║██╔════╝██╔══██╗  
  ███████╗██║     ███████║██╔██╗ ██║██╔██╗ ██║█████╗  ██████╔╝  
  ╚════██║██║     ██╔══██║██║╚██╗██║██║╚██╗██║██╔══╝  ██╔══██╗  
  ███████║╚██████╗██║  ██║██║ ╚████║██║ ╚████║███████╗██║  ██║  
  ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝  
                                                            
  "
}

# Function to display help
show_help() {
  echo "
Usage: $0 [OPTIONS]

This script scans the specified subnet ($SCAN_SUBNET) for active hosts and displays ARP table entries.

Options:
  -h, --help    Show this help message
"
}

# Function for error handling
error_exit() {
  echo "Error: $1" >&2
  exit 1
}

# Function to generate the list of /24 subnets in a /22 range
generate_subnets() {
  local base_subnet
  base_subnet=$(echo "$SCAN_SUBNET" | cut -d'/' -f1) || error_exit "Invalid subnet format"
  local subnet_prefix
  subnet_prefix=$(echo "$SCAN_SUBNET" | cut -d'/' -f2) || error_exit "Invalid subnet format"

  if [[ "$subnet_prefix" -ne 22 ]]; then
    error_exit "Only /22 subnets are supported. Provided: /$subnet_prefix"
  fi

  local base_a base_b base_c
  IFS='.' read -r base_a base_b base_c _ <<<"$base_subnet"

  for third_octet in $(seq "$base_c" $((base_c + 3))); do
    echo "$base_a.$base_b.$third_octet"
  done
}

# Function to scan a single /24 subnet
scan_subnet() {
  local subnet="$1"
  echo "Scanning subnet ${subnet}.0/24..."
  for i in {1..254}; do
    ping -i 0.1 -W 100 -c 1 "$subnet.$i" &>/dev/null && echo "Host found: $subnet.$i" &
  done
  wait || {
    error_exit "Error during subnet scan for $subnet"
  }
}

# Function to process ARP table
process_arp_table() {
  local primary_interface="$1"
  echo "Retrieving ARP table entries..."
  arp -a | grep "$primary_interface" | \
    sed -e 's/^\?/unnamed/' \
        -e "s/\ at\ /${TAB}/g" \
        -e "s/\ on\ /${TAB}/g" \
        -e 's/\ ifscope.*$//g' | \
    awk -v tab="$TAB" 'BEGIN {
      FS = tab
      OFS = tab
      printf "%-17s %-12s %-15s %-15s\n", "MAC", "INTERFACE", "HOSTNAME", "IP"
      printf "%-17s %-12s %-15s %-15s\n", "─────────────────", "────────────", "───────────────", "───────────────"
    } {
      if ($2 != "(incomplete)") {
        # Parse hostname and IP
        ip = "UNKNOWN"
        hostname = $1
        if ($1 ~ /\(.*\)/) {
          sub(/\(.*\)/, "", hostname)
          gsub(/[()]/, "", $1)
          split($1, arr, " ")
          ip = arr[length(arr)]
        }
        printf "%-17s %-12s %-15s %-15s\n", $2, $3, hostname, ip
      }
    }' || {
    error_exit "Failed to process ARP table"
  }
}

# Main logic function
main_logic() {
  echo "Starting scan for the $SCAN_SUBNET range..."
  local primary_interface
  primary_interface=$(get_primary_interface) || error_exit "Failed to retrieve primary network interface"

  local subnets
  subnets=$(generate_subnets) || error_exit "Failed to generate subnets for $SCAN_SUBNET"

  for subnet in $subnets; do
    scan_subnet "$subnet"
  done

  process_arp_table "$primary_interface"
}

# Function to get the primary network interface
get_primary_interface() {
  local primary_interface
  primary_interface=$(echo "show State:/Network/Global/IPv4" | scutil | awk -F: '/PrimaryInterface/ { sub(/ /, "", $2); print $2 }') || {
    error_exit "Failed to determine the primary network interface"
  }
  echo "$primary_interface"
}

# Main function to encapsulate script logic
main() {
  if [[ $# -gt 0 ]]; then
    case "$1" in
      -h|--help)
        show_help
        exit 0
        ;;
      *)
        error_exit "Invalid option: $1"
        ;;
    esac
  fi

  main_logic
}

# Print ASCII Art
print_ascii_art

# Execute the main function
main "$@"