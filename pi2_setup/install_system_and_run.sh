#!/bin/bash
    # ======================================================================
    # !!! CRUCIAL CONFIGURATION STEP - MUST BE EDITED MANUALLY !!!
    # ======================================================================
    REPO_URL="https://github.com/jmoney136/jarvis-raspi-for-magicmirror.git"       # <<< EDIT THIS with the actual Git URL
    ETH_IP="<PLACEHOLDER_ETH_IP>"               # <<< EDIT THIS with the Pi 2 static IP (e.g.,192.168.50.2)
    SSID="Wifi with extra viruses"                   # <<< EDIT THIS with your Wi-Fi Network Name
    WIFI_PASSWORD="p@55w0rd" # <<< EDIT THIS with your Wi-Fi Password
    # ======================================================================
    
    TARGET_DIR="./pi2_setup"
    GIT_DIR="$TARGET_DIR/jarvis_raspi"
    
    # --- Network Wait Logic ---
    TARGET_HOST="8.8.8.8"  # Use a reliable external host for testing connectivity
    MAX_RETRIES=10
    WAIT_TIME=5          # Wait 5 seconds between retries
    
    echo "--- Starting Pi 2 Setup ---"
    
    # 1. System Setup & Network Configuration (using nmcli)
    echo "Setting up networking on Pi 2..."
    echo "Attempting to configure network using nmcli (requires manual confirmation for Wi-Fi)..."
    # Example commands for demonstration:
    sudo nmcli dev wifi connect "$SSID" password "$WIFI_PASSWORD" ifname wlan0
    echo "Network configuration steps are outlined but require manual execution/verification."
    
    
    # 2. Wait for Active Network Connection
    echo "--- Checking for active network connection to $TARGET_HOST... ---"
    NETWORK_READY=false
    for i in $(seq 1 $MAX_RETRIES); do
        echo "Attempt $i of $MAX_RETRIES: Pinging $TARGET_HOST..."
        # Check if ping is successful (exit code 0)
        if ping -c 1 -W 1 "$TARGET_HOST" > /dev/null 2>&1; then
            echo "SUCCESS: Network connection established."
            NETWORK_READY=true
            break
        else
            echo "Connection failed. Waiting $WAIT_TIME seconds before retrying..."
            sleep $WAIT_TIME
        fi
    done
    
    # Check the result of the network wait
    if [ "$NETWORK_READY" = false ]; then
    echo "ERROR: Failed to establish a stable network connection after $MAX_RETRIES attempts.
    Aborting setup."
        exit 1
    fi
    # --- End of Network Wait Logic ---
    
    
    # 3. Clone the repository
    echo "Cloning repository from $REPO_URL into $GIT_DIR..."
    if [ -d "$GIT_DIR" ]; then
        echo "Repository already exists. Skipping clone."
    else
        git clone "$REPO_URL" "$GIT_DIR"
        if [ $? -ne 0 ]; then
            echo "ERROR: Failed to clone repository. Check the REPO_URL or network access."
            exit 1
        fi
    fi
    echo "Repository cloned successfully."
    
    # 4. Run generalized application setup
    echo "Running generalized application setup script..."
    if [ -f "../application_setup.sh" ]; then
        bash "../application_setup.sh"
    else
        echo "ERROR: application_setup.sh not found. Cannot run generalized setup."
        exit 1
    fi
    
    echo "--- Pi 2 Setup Complete ---"
    echo "NOTE: Network setup (Step 1) requires manual intervention for Wi-Fi connection."