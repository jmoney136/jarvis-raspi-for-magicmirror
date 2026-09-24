#!/bin/bash

# Script to install Jarvis for Raspi on Pi 1

echo "--- Starting installation for Pi 1 ---"

#install system packages, ensure git is installed
sudo apt update && sudo apt upgrade
sudo apt install git
#clone git repo
git clone $REPO
# Navigate to the project directory
cd /Users/jasparryding/Desktop/projects/jarvis for raspi/jarvis raspi, for magicmirror/jarvis_for_raspi_repo

echo "Navigated to project directory."

# Install dependencies
echo "Installing project dependencies..."
npm install

if [ 0 -eq 0 ]; then
    echo "Dependencies installed successfully."
else
    echo "ERROR: Dependency installation failed. Please check the logs above."
    exit 1
fi

# Run the application
echo "Running Jarvis application..."
npm start

echo "--- Installation and startup process for Pi 1 completed. ---"
