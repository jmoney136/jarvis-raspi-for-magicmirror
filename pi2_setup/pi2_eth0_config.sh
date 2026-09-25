#!/bin/bash
    
    # --- Configuration for MagicMirror Pi (The Client) ---
    # !!! EDIT THESE VALUES BEFORE RUNNING !!!
    STATIC_IP="192.168.1.10"      # Static IP for the MagicMirror Pi (Client)
    GATEWAY_IP="192.168.1.1"     # The IP of the Jarvis Pi (Gateway)
    NETPLAN_FILE="/etc/netplan/00-installer-config.yaml"
    
    echo "--- Network Configuration for MagicMirror Pi (Client) ---"
    
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
          gateway4: ${GATEWAY_IP}
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
    echo "Check the IP address on the MagicMirror Pi: ip a"