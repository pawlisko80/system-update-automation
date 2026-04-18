#!/bin/bash
# =============================================================
# network-check.sh — Network topology checker for homelab
# Pings all known hosts and reports up/down status
# Configure HOSTS below with your homelab devices
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

LOG_DIR="$HOME/logs/network"
LOG_FILE="$LOG_DIR/network-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$LOG_DIR"

# =============================================================
# Configuration — add your homelab hosts here
# Format: "IP|Hostname|Description"
# =============================================================
HOSTS=(
    "10.20.30.1|router|OPNsense Router"
    "10.20.30.2|switch|Core Switch"
    "10.20.30.10|nas|QNAP NAS"
    "10.20.30.20|proxmox|Proxmox Hypervisor"
    "10.20.30.25|hdhomerun|HDHomeRun Tuner"
    "10.20.30.33|homeassistant|Home Assistant"
    "10.20.30.34|qbittorrent|qBittorrent"
    "10.20.30.35|peanut|PeaNUT UPS Monitor"
)

# Timeout in seconds for each ping
TIMEOUT=2
# Number of ping packets
COUNT=1

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

up()   { echo -e "${GREEN}  ✅ UP   $1${NC}" | tee -a "$LOG_FILE"; }
down() { echo -e "${RED}  ❌ DOWN $1${NC}" | tee -a "$LOG_FILE"; }
info() { echo -e "${BLUE}  ℹ️  $1${NC}" | tee -a "$LOG_FILE"; }

TOTAL=0
UP_COUNT=0
DOWN_COUNT=0

echo "============================================================" | tee -a "$LOG_FILE"
echo "  Network Topology Check — $(date)" | tee -a "$LOG_FILE"
echo "  From: $(hostname)" | tee -a "$LOG_FILE"
echo "============================================================" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# =============================================================
# Ping all configured hosts
# =============================================================
printf "%-18s %-20s %-25s %s\n" "IP" "Hostname" "Description" "Status" | tee -a "$LOG_FILE"
echo "────────────────────────────────────────────────────────────" | tee -a "$LOG_FILE"

for entry in "${HOSTS[@]}"; do
    IP=$(echo "$entry" | cut -d'|' -f1)
    HOST=$(echo "$entry" | cut -d'|' -f2)
    DESC=$(echo "$entry" | cut -d'|' -f3)
    TOTAL=$((TOTAL+1))

    if ping -c $COUNT -W $TIMEOUT "$IP" &>/dev/null 2>&1; then
        # Get latency
        LATENCY=$(ping -c 1 -W $TIMEOUT "$IP" 2>/dev/null | grep "time=" | awk -F'time=' '{print $2}' | awk '{print $1}')
        printf "%-18s %-20s %-25s " "$IP" "$HOST" "$DESC" | tee -a "$LOG_FILE"
        echo -e "${GREEN}UP${NC} (${LATENCY}ms)" | tee -a "$LOG_FILE"
        UP_COUNT=$((UP_COUNT+1))
    else
        printf "%-18s %-20s %-25s " "$IP" "$HOST" "$DESC" | tee -a "$LOG_FILE"
        echo -e "${RED}DOWN${NC}" | tee -a "$LOG_FILE"
        DOWN_COUNT=$((DOWN_COUNT+1))
    fi
done

# =============================================================
# DNS check
# =============================================================
echo "" | tee -a "$LOG_FILE"
echo "━━━ DNS Resolution ━━━" | tee -a "$LOG_FILE"
for domain in google.com github.com anthropic.com; do
    if host "$domain" &>/dev/null 2>&1 || nslookup "$domain" &>/dev/null 2>&1; then
        echo -e "${GREEN}  ✅ DNS: $domain resolved${NC}" | tee -a "$LOG_FILE"
    else
        echo -e "${RED}  ❌ DNS: $domain failed${NC}" | tee -a "$LOG_FILE"
    fi
done

# =============================================================
# Internet latency
# =============================================================
echo "" | tee -a "$LOG_FILE"
echo "━━━ Internet Latency ━━━" | tee -a "$LOG_FILE"
for target in "8.8.8.8|Google DNS" "1.1.1.1|Cloudflare DNS" "9.9.9.9|Quad9 DNS"; do
    IP=$(echo "$target" | cut -d'|' -f1)
    NAME=$(echo "$target" | cut -d'|' -f2)
    LATENCY=$(ping -c 3 -W 3 "$IP" 2>/dev/null | tail -1 | awk -F'/' '{print $5}')
    if [ -n "$LATENCY" ]; then
        echo -e "${GREEN}  ✅ $NAME ($IP): ${LATENCY}ms avg${NC}" | tee -a "$LOG_FILE"
    else
        echo -e "${RED}  ❌ $NAME ($IP): unreachable${NC}" | tee -a "$LOG_FILE"
    fi
done

# =============================================================
# Summary
# =============================================================
echo "" | tee -a "$LOG_FILE"
echo "============================================================" | tee -a "$LOG_FILE"
echo "  Results: $UP_COUNT/$TOTAL hosts up, $DOWN_COUNT down" | tee -a "$LOG_FILE"

if [ "$DOWN_COUNT" -eq 0 ]; then
    echo -e "${GREEN}  ✅ All hosts reachable${NC}" | tee -a "$LOG_FILE"
else
    echo -e "${RED}  ❌ $DOWN_COUNT host(s) unreachable${NC}" | tee -a "$LOG_FILE"
fi
echo "  Log saved to $LOG_FILE" | tee -a "$LOG_FILE"
echo "============================================================" | tee -a "$LOG_FILE"
echo ""
echo "Press ENTER to close..."
read -r
