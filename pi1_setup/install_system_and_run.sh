#!/bin/bash

  # --- Configuration for Pi 1 ---
  REPO_URL="<PLACEHOLDER_REPO_URL_PI1>"
  TARGET_DIR="./pi1_setup"
  GIT_DIR="$TARGET_DIR/jarvis_raspi"
  # --- End Configuration ---

  echo "--- Starting Pi 1 Setup ---"

  # 1. Create directory structure
  echo "Creating directory structure for Pi 1..."
  mkdir -p "$TARGET_DIR"

  # 2. Clone the repository
  echo "Cloning repository from $REPO_URL into $GIT_DIR..."
  if [ -d "$GIT_DIR" ]; then
      echo "Repository already exists. Skipping clone."
  else
      git clone "$REPO_URL" "$GIT_DIR"
      if [ $? -ne 0 ]; then
          echo "ERROR: Failed to clone repository. Check the REPO_URL."
          exit 1
      fi
  fi
  echo "Repository cloned successfully."

  # 3. Run generalized application setup
  echo "Running generalized application setup script..."
  if [ -f "../application_setup.sh" ]; then
      bash "../application_setup.sh"
  else
      echo "ERROR: application_setup.sh not found. Cannot run generalized setup."
      exit 1
  fi

  echo "--- Pi 1 Setup Complete ---"