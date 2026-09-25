  #!/bin/bash
  # Script for setting up Jarvis on Raspberry Pi 1

  echo "--- Starting Pi 1 System Setup ---"

  # 1. System Updates and Dependencies
  echo "Updating system packages..."
  sudo apt update -y
  sudo apt upgrade -y

  echo "Installing necessary dependencies..."
  # Install core dependencies for a Raspberry Pi setup
  sudo apt install -y git python3 python3-pip

  # 2. Repository Cloning
  REPO_URL="[PLACEHOLDER_REPO_URL_PI1]"
  REPO_DIR="/opt/jarvis_pi1"

  echo "Cloning Jarvis repository from: $REPO_URL"
  if [ -d "$REPO_DIR" ]; then
      echo "Repository directory already exists. Skipping clone."
  else
      mkdir -p "$REPO_DIR"
      git clone "$REPO_URL" "$REPO_DIR"
      if [ $? -eq 0 ]; then
          echo "Repository cloned successfully to $REPO_DIR."
      else
          echo "Error: Failed to clone repository. Check REPO_URL."
          exit 1
      fi
  fi

  echo "Pi 1 setup script finished."