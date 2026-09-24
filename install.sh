#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${ROOT_DIR}/.venv"
INSTALL_SYSTEM_PACKAGES=1
ENABLE_SERVICE=0
INSTALL_OLLAMA=1
OLLAMA_MODEL="${JARVIS_OLLAMA_MODEL:-qwen2.5:0.5b}"

usage() {
    cat <<EOF
Usage: $0 [--no-apt] [--no-ollama] [--enable-service]

    --no-apt           Do not install Raspberry Pi OS packages.
    --no-ollama        Skip Ollama installation and model pull.
  --enable-service   Install and enable the offline systemd service.

The Ollama model is downloaded during installation. Runtime uses only the
local Ollama service; no hosted API is used.
EOF
}

for argument in "$@"; do
    case "$argument" in
        --no-apt) INSTALL_SYSTEM_PACKAGES=0 ;;
        --no-ollama) INSTALL_OLLAMA=0 ;;
        --enable-service) ENABLE_SERVICE=1 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $argument" >&2; usage >&2; exit 2 ;;
    esac
done

if [[ "$(uname -s)" != "Linux" ]]; then
    echo "This installer targets Raspberry Pi OS/Linux." >&2
    exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 is required. Install it or rerun without --no-apt on Raspberry Pi OS." >&2
    exit 1
fi

python3 - <<'PY'
import sys
if sys.version_info < (3, 11):
    raise SystemExit("Python 3.11 or newer is required")
PY

if [[ "$INSTALL_SYSTEM_PACKAGES" == 1 ]]; then
    if ! command -v sudo >/dev/null 2>&1; then
        echo "sudo is required for package installation; use --no-apt if dependencies are already installed." >&2
        exit 1
    fi
    sudo apt-get update
    sudo apt-get install -y python3-venv python3-pip alsa-utils curl
fi

if [[ "$INSTALL_OLLAMA" == 1 ]]; then
    if ! command -v curl >/dev/null 2>&1; then
        echo "curl is required to install Ollama; install it or use --no-ollama." >&2
        exit 1
    fi
    if ! command -v ollama >/dev/null 2>&1; then
        curl -fsSL https://ollama.com/install.sh | sh
    fi
    if ! command -v ollama >/dev/null 2>&1; then
        echo "Ollama installation did not provide the ollama command." >&2
        exit 1
    fi
    if command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files ollama.service >/dev/null 2>&1; then
        if [[ "$(id -u)" -eq 0 ]]; then
            systemctl enable --now ollama.service
        else
            sudo systemctl enable --now ollama.service
        fi
    fi
    ollama pull "${OLLAMA_MODEL}"
fi

mkdir -p "${ROOT_DIR}/data" "${ROOT_DIR}/models"
if [[ ! -f "${ROOT_DIR}/.env" ]]; then
    cp "${ROOT_DIR}/.env.example" "${ROOT_DIR}/.env"
    echo "Created .env from .env.example; review local binary/model paths."
fi

if [[ ! -x "${VENV_DIR}/bin/python" ]]; then
    python3 -m venv "${VENV_DIR}"
fi
"${VENV_DIR}/bin/python" -m pip install --upgrade pip
"${VENV_DIR}/bin/python" -m pip install --editable "${ROOT_DIR}"

if [[ "$ENABLE_SERVICE" == 1 ]]; then
    if [[ "$(id -u)" -eq 0 ]]; then
        SUDO=""
    else
        SUDO="sudo"
    fi
    SERVICE_PATH="/etc/systemd/system/jarvis.service"
    sed -e "s#User=pi#User=$(id -un)#" \
        -e "s#WorkingDirectory=/home/pi/jarvis#WorkingDirectory=${ROOT_DIR}#" \
        -e "s#EnvironmentFile=-/home/pi/jarvis/.env#EnvironmentFile=-${ROOT_DIR}/.env#" \
        -e "s#ExecStart=/home/pi/jarvis/.venv/bin/python#ExecStart=${VENV_DIR}/bin/python#" \
        -e "s#ReadWritePaths=/home/pi/jarvis/data#ReadWritePaths=${ROOT_DIR}/data#" \
        "${ROOT_DIR}/deploy/jarvis.service" | ${SUDO} tee "${SERVICE_PATH}" >/dev/null
    ${SUDO} systemctl daemon-reload
    ${SUDO} systemctl enable --now jarvis.service
fi

echo
echo "Jarvis installed in ${ROOT_DIR}."
echo "Text test: ${VENV_DIR}/bin/python -m jarvis --text \"what time is it\""
echo "Voice mode: ${VENV_DIR}/bin/python -m jarvis"
if [[ "$INSTALL_OLLAMA" == 1 ]]; then
    echo "Ollama model installed: ${OLLAMA_MODEL}"
else
    echo "Ollama was skipped; install it later or use --no-ollama."
fi
