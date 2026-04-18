#!/bin/bash
# =============================================================
# network-check.sh - Network topology checker for homelab
# Reads hosts from common/hosts.conf
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOSTS_CONF="$SCRIPT_DIR/hosts.conf"

LOG_DIR="$HOME/logs/network"
LOG_FILE="$LOG_DIR/network-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$LOG_DIR"

TIMEOUT=2
COUNT=1

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

write_log()    { local m="$1"; local ts; ts=$(date '+%Y-%m-%d %H:%M:%S'); echo "[$ts] $m" | tee -a "$LOG_FILE"; }
write_ok()     { echo -e "${GREEN}  OK  $1${NC}" | tee -a "$LOG_FILE"; }
write_crit()   { echo -e "${RED}  ERR $1${NC}" | tee -a "$LOG_FILE"; }
write_info()   { echo -e "${BLUE}  INF $1${NC}" | tee -a "$LOG_FILE"; }
write_section(){ echo "" | tee -a "$LOG_FILE"; echo "--- $1 ---" | tee -a "$LOG_FILE"; }
write_sep()    { echo "============================================================" | tee -a "$LOG_FILE"; }

# Check hosts.conf exists
if [ ! -f "$HOSTS_CONF" ]; then
    echo "ERROR: hosts.conf not found at $HOSTS_CONF"
    echo "Create it with format: IP|Name|Description"
    exit 1
fi

write_sep
write_log "Network Topology Check - $(date)"
write_log "From: $(hostname)"
write_log "Config: $HOSTS_CONF"
write_sep

TOTAL=0
UP_COUNT=0
DOWN_COUNT=0

# =============================================================
# Ping all hosts from hosts.conf
# =============================================================
write_section "Homelab Hosts"
printf "  %-18s %-20s %-25s %s\n" "IP" "Name" "Description" "Status" | tee -a "$LOG_FILE"
echo "  $(printf '%.0s-' {1..70})" | tee -a "$LOG_FILE"

while IFS='|' read -r ip name desc; do
    # Skip comments and empty lines
    [[ "$ip" =~ ^#.*$ ]] && continue
    [[ -z "$ip" ]] && continue

    TOTAL=$((TOTAL+1))

    if ping -c $COUNT -W $TIMEOUT "$ip" &>/dev/null 2>&1; then
        LATENCY=$(ping -c 1 -W $TIMEOUT "$ip" 2>/dev/null | grep "time=" | awk -F'time=' '{print $2}' | awk '{print $1}')
        printf "  %-18s %-20s %-25s " "$ip" "$name" "$desc" | tee -a "$LOG_FILE"
        echo -e "${GREEN}UP${NC} (${LATENCY}ms)" | tee -a "$LOG_FILE"
        UP_COUNT=$((UP_COUNT+1))
    else
        printf "  %-18s %-20s %-25s " "$ip" "$name" "$desc" | tee -a "$LOG_FILE"
        echo -e "${RED}DOWN${NC}" | tee -a "$LOG_FILE"
        DOWN_COUNT=$((DOWN_COUNT+1))
    fi
done < "$HOSTS_CONF"

# =============================================================
# DNS check
# =============================================================
write_section "DNS Resolution"
for domain in google.com github.com anthropic.com; do
    if host "$domain" &>/dev/null 2>&1 || nslookup "$domain" &>/dev/null 2>&1; then
        write_ok "DNS: $domain resolved"
    else
        write_crit "DNS: $domain failed"
    fi
done

# =============================================================
# Internet latency
# =============================================================
write_section "Internet Latency"
for target in "8.8.8.8|Google DNS" "1.1.1.1|Cloudflare DNS" "9.9.9.9|Quad9 DNS"; do
    IP=$(echo "$target" | cut -d'|' -f1)
    NAME=$(echo "$target" | cut -d'|' -f2)
    LATENCY=$(ping -c 3 -W 3 "$IP" 2>/dev/null | tail -1 | awk -F'/' '{print $5}')
    if [ -n "$LATENCY" ]; then
        write_ok "$NAME ($IP): ${LATENCY}ms avg"
    else
        write_crit "$NAME ($IP): unreachable"
    fi
done

# =============================================================
# Summary
# =============================================================
echo "" | tee -a "$LOG_FILE"
write_sep
write_log "Results: $UP_COUNT/$TOTAL hosts up, $DOWN_COUNT down"
if [ "$DOWN_COUNT" -eq 0 ]; then
    write_ok "All hosts reachable"
else
    write_crit "$DOWN_COUNT host(s) unreachable"
fi
write_log "Log saved to $LOG_FILE"
write_sep
echo ""
echo "Press ENTER to close..."
read -r
