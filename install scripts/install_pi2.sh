#!/bin/bash

# ==========================================================
# Jarvis for Raspi Installation Script for Pi 2
# ==========================================================
echo "=========================================================="
echo " Jarvis for Raspi Installation Script for Raspberry Pi 2"
echo "=========================================================="
#system update + git install
sudo apt update && sudo apt upgrade
sudo apt install git
# --- Configuration ---
# !!! IMPORTANT: Update these variables before running !!!
PROJECT_DIR="/Users/jasparryding/Desktop/projects/jarvis for raspi/jarvis raspi, for magicmirror/jarvis_for_raspi_repo"
REPO_URL="<REPOSITORY_URL_FOR_PI2>" # !!! Replace with the actual repository URL !!!

echo "Starting installation process for Pi 2..."

# 1. Check for necessary tools (Node.js, npm, git)
echo "Checking for required tools (Node.js, npm, git)..."
if ! command -v node &> /dev/null || ! command -v npm &> /dev/null || ! command -v git &> /dev/null; then
    echo "ERROR: Required tools (Node.js, npm, or git) are not installed."
    echo "Please install them before proceeding."
    exit 1
fi

# 2. Navigate to the project directory
echo "Navigating to project directory: "
cd ""

if [ 0 -ne 0 ]; then
    echo "ERROR: Failed to navigate to the project directory. Check the path specified in the script."
    exit 1
fi

# 3. Clone the repository (if not already cloned)
if [ ! -d "jarvis_for_raspi_repo" ]; then
    echo "Cloning repository"
    git clone $REPO_URL
    if [ 0 -ne 0 ]; then
        echo "ERROR: Git clone failed. Please check the repository URL and your Git setup."
        exit 1
    fi
    cd jarvis_for_raspi_repo
else
    echo "Repository already exists. Skipping clone."
fi

# 4. Install Dependencies
echo "Installing project dependencies using npm..."
npm install

if [ 0 -eq 0 ]; then
    echo "✅ Dependencies installed successfully."
else
    echo "❌ ERROR: Dependency installation failed. Please check the npm output above for details."
    exit 1
fi

# 5. Run the Application
echo "Starting Jarvis application..."
npm start

echo "=========================================================="
echo "🎉 Installation and startup process for Pi 2 completed successfully!"
echo "=========================================================="
