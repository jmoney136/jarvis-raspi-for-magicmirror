#!/bin/bash

  # --- Configuration ---
  VENV_DIR="./venv"
  OLLAMA_INSTALL_DIR="$HOME/.ollama"
  SERVICE_NAME="jarvis_service.service"
  # --- End Configuration ---

  echo "--- Starting Generalized Application Setup ---"

  # 1. Setup Python Virtual Environment
  echo "Setting up Python Virtual Environment..."
  if [ ! -d "$VENV_DIR" ]; then
      python3 -m venv "$VENV_DIR"
  fi
  source "$VENV_DIR/bin/activate"
  echo "Python Virtual Environment created and activated."

  # 2. Install Ollama
  echo "Installing Ollama..."
  if command -v ollama &> /dev/null; then
      echo "Ollama is already installed."
  else
      # Assuming installation via curl/wget, adjust if necessary for your specific Pi OS setup
      curl -fsSL https://ollama.com/install.sh | sh
  fi
  echo "Ollama installation complete."

  # 3. Install necessary Python packages (Example - adjust as needed)
  echo "Installing required Python packages..."
  pip install -r requirements.txt 2>/dev/null || echo "requirements.txt not found. Skipping package
  installation."

  # 4. Create Systemd Service File
  echo "Creating systemd service file: $SERVICE_NAME"
  cat <<EOF > /etc/systemd/system/$SERVICE_NAME
  [Unit]
  Description=Jarvis AI Service

  [Service]
  User=$USER
  WorkingDirectory=$HOME/jarvis_for_raspi/jarvis_raspi_for_magicmirror
  ExecStart=/home/$USER/jarvis_for_raspi/jarvis_raspi_for_magicmirror/venv/bin/python main.py
  Restart=always
  Environment="OLLAMA_HOST=http://localhost:11434"

  [Install]
  WantedBy=multi-user.target
  EOF

  echo "Systemd service file created."
  echo "--- Generalized Setup Complete ---"
  echo "Remember to enable and start the service later with: sudo systemctl daemon-reload && sudo
  systemctl enable $SERVICE_NAME && sudo systemctl start $SERVICE_NAME"