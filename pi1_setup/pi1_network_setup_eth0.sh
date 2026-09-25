#!/bin/bash
    
    # --- Configuration for Jarvis Pi ---
    # !!! YOU MUST EDIT THESE VALUES BEFORE RUNNING !!!
    STATIC_IP="192.168.1.1"       # The static IP for the Jarvis Pi (Gateway)
    NETPLAN_FILE="/etc/netplan/00-installer-config.yaml"
    
    echo "--- Network Configuration for Jarvis Pi ---"
    
    # Check if the file exists
    if [ ! -f "$NETPLAN_FILE" ]; then
        echo "ERROR: Netplan file not found at $NETPLAN_FILE. Please check the path."
        exit 1
    fi
    
    # Create the configuration content dynamically
    CONFIG_CONTENT=$(cat <<EOF
    network:
      version: 2
      ethernets:
        eth0:
          dhcp4: no
          addresses: [${STATIC_IP}/24]
          gateway4: ${STATIC_IP}
          nameservers:
            addresses: [8.8.8.8, 8.8.4.4]
    EOF
    )
    
    # Write the configuration to the file
    echo "$CONFIG_CONTENT" | sudo tee "$NETPLAN_FILE" > /dev/null
    
    echo "Configuration written to $NETPLAN_FILE."
    echo "Applying network changes..."
    sudo netplan apply
    
    echo "--- Configuration Complete ---"
    echo "Check the IP address on the Jarvis Pi: ip a"