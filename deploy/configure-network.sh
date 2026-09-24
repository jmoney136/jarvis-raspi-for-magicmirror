#!/usr/bin/env bash
set -Eeuo pipefail

ROLE=""
ETH_IP=""
SSID=""
WIFI_PASSWORD=""
WIFI_ENABLED=1
ETH_IF=""
WIFI_IF=""
PREFIX=24

usage() {
    cat <<'EOF'
Usage:
  sudo ./configure-network.sh --role brain --ip 192.168.50.1 --ssid MyWifi
  sudo ./configure-network.sh --role face  --ip 192.168.50.2 --ssid MyWifi
  sudo ./configure-network.sh --role face  --ip 192.168.50.2 --no-wifi

Options:
  --role brain|face       Device role; required.
  --ip ADDRESS            Static Ethernet address; required.
  --ssid NAME             Wi-Fi network name; prompts if omitted.
  --password PASSWORD     Avoid when possible; prompts securely if omitted.
  --no-wifi               Configure Ethernet only.
  --ethernet IFACE        Ethernet interface, default: eth0.
  --wifi IFACE            Wi-Fi interface, default: wlan0.
  --help                  Show this help.

The Ethernet connection is configured without a default route. Wi-Fi remains
responsible for internet access. Run this script locally on each Raspberry Pi.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --role) ROLE="${2:?Missing value for --role}"; shift 2 ;;
        --ip) ETH_IP="${2:?Missing value for --ip}"; shift 2 ;;
        --ssid) SSID="${2:?Missing value for --ssid}"; shift 2 ;;
        --password) WIFI_PASSWORD="${2:?Missing value for --password}"; shift 2 ;;
        --no-wifi) WIFI_ENABLED=0; shift ;;
        --ethernet) ETH_IF="${2:?Missing value for --ethernet}"; shift 2 ;;
        --wifi) WIFI_IF="${2:?Missing value for --wifi}"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
done

if [[ "$(id -u)" -ne 0 ]]; then
    echo "Run this script with sudo." >&2
    exit 1
fi

if [[ "$(uname -s)" != "Linux" ]]; then
    echo "This script targets Raspberry Pi OS/Linux." >&2
    exit 1
fi

if ! command -v nmcli >/dev/null 2>&1; then
    echo "nmcli was not found. Install NetworkManager and enable its service first." >&2
    exit 1
fi

case "$ROLE" in
    brain|face) ;;
    *) echo "--role must be brain or face." >&2; exit 2 ;;
esac

if [[ -z "$ETH_IP" ]]; then
    echo "--ip is required." >&2
    exit 2
fi
if [[ ! "$ETH_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    echo "Invalid IPv4 address: $ETH_IP" >&2
    exit 2
fi

ETH_IF="${ETH_IF:-eth0}"
WIFI_IF="${WIFI_IF:-wlan0}"
ETH_CONNECTION="jarvis-ethernet"
WIFI_CONNECTION="jarvis-wifi"

if [[ "$WIFI_ENABLED" == 1 ]]; then
    if [[ -z "$SSID" ]]; then
        read -r -p "Wi-Fi SSID: " SSID
    fi
    if [[ -z "$WIFI_PASSWORD" ]]; then
        read -r -s -p "Wi-Fi password (input hidden): " WIFI_PASSWORD
        printf '\n'
    fi
    nmcli connection delete "$WIFI_CONNECTION" >/dev/null 2>&1 || true
    nmcli device wifi connect "$SSID" password "$WIFI_PASSWORD" ifname "$WIFI_IF" name "$WIFI_CONNECTION"
    unset WIFI_PASSWORD
    nmcli connection modify "$WIFI_CONNECTION" connection.autoconnect yes connection.autoconnect-priority 20 ipv4.method auto ipv6.method auto
    nmcli connection up "$WIFI_CONNECTION"
fi

nmcli connection delete "$ETH_CONNECTION" >/dev/null 2>&1 || true
nmcli connection add type ethernet ifname "$ETH_IF" con-name "$ETH_CONNECTION" \
    ipv4.method manual ipv4.addresses "${ETH_IP}/${PREFIX}" \
    ipv4.never-default yes ipv6.method disabled \
    connection.autoconnect yes connection.autoconnect-priority 10
nmcli connection up "$ETH_CONNECTION"

if [[ "$ROLE" == brain ]]; then
    echo "Brain Pi configured: Ethernet ${ETH_IP}/${PREFIX}; Wi-Fi provides internet."
else
    echo "Face Pi configured: Ethernet ${ETH_IP}/${PREFIX}; Ethernet has no internet route."
fi
nmcli connection show --active
