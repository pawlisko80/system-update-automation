#!/bin/sh
# =============================================================
# update-ddwrt — DD-WRT router maintenance script
# Covers: package updates (optware/entware), firmware check
# Run directly on DD-WRT via SSH (BusyBox/ash shell)
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

LOG_DIR="/tmp/logs/ddwrt"
LOG_FILE="$LOG_DIR/ddwrt-update.log"

mkdir -p "$LOG_DIR"

write_log() {
    message="$1"
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

write_separator() {
    echo "============================================================" | tee -a "$LOG_FILE"
}

write_separator
write_log "📡 DD-WRT update started - $(date)"
write_log "📋 Version: $(cat /tmp/loginprompt 2>/dev/null | head -2 || nvram get os_version 2>/dev/null || echo 'unknown')"
write_log "📋 Model: $(nvram get DD_BOARD 2>/dev/null || nvram get board_name 2>/dev/null || echo 'unknown')"
write_log "📋 Hostname: $(nvram get wan_hostname 2>/dev/null || hostname)"
write_separator

# NOTE: DD-WRT uses /tmp filesystem which is RAM-based and resets on reboot
write_log ""
write_log "⚠️  NOTE: DD-WRT logs in /tmp are lost on reboot."
write_log "    For persistent logs, mount a USB drive and change LOG_DIR."

# =============================================================
# Optware/Entware packages (if installed)
# =============================================================
write_log ""
write_log "📦 Checking Optware/Entware packages..."

if command -v opkg >/dev/null 2>&1; then
    write_log "⬆️  Updating opkg package list..."
    opkg update 2>&1 | tee -a "$LOG_FILE"
    write_log "⬆️  Upgrading packages..."
    opkg upgrade 2>&1 | tee -a "$LOG_FILE"
    write_log "✅ opkg update complete."
elif command -v ipkg >/dev/null 2>&1; then
    write_log "⬆️  Updating ipkg packages (legacy Optware)..."
    ipkg update 2>&1 | tee -a "$LOG_FILE"
    ipkg upgrade 2>&1 | tee -a "$LOG_FILE"
    write_log "✅ ipkg update complete."
else
    write_log "ℹ️  No package manager found (opkg/ipkg)."
    write_log "    Install Entware for package management support."
fi

# =============================================================
# Firmware check (informational only)
# =============================================================
write_log ""
write_log "🔧 Firmware information..."
CURRENT_VER=$(nvram get dd_version 2>/dev/null || nvram get os_version 2>/dev/null || echo "unknown")
write_log "   Current version: $CURRENT_VER"
write_log "ℹ️  Check for DD-WRT firmware updates at:"
write_log "   https://dd-wrt.com/support/router-database/"
write_log "   Web UI: Administration → Firmware Upgrade"
write_log "⚠️  Always back up NVRAM before flashing: Administration → Backup"

# =============================================================
# NVRAM backup
# =============================================================
write_log ""
write_log "💾 NVRAM info..."
NVRAM_USED=$(nvram show 2>/dev/null | grep "size:" | awk '{print $2}')
write_log "   NVRAM usage: ${NVRAM_USED:-unknown}"

# =============================================================
# Network status
# =============================================================
write_log ""
write_log "🌐 Network interfaces..."
ifconfig 2>/dev/null | grep -E "^[a-z]|inet addr" | tee -a "$LOG_FILE"

# =============================================================
# WAN status
# =============================================================
write_log ""
write_log "🌐 WAN status..."
WAN_IP=$(nvram get wan_ipaddr 2>/dev/null)
WAN_GW=$(nvram get wan_gateway 2>/dev/null)
write_log "   WAN IP: ${WAN_IP:-unknown}"
write_log "   Gateway: ${WAN_GW:-unknown}"

# =============================================================
# Done
# =============================================================
write_log ""
write_separator
write_log "✅ All done! Log saved to $LOG_FILE (RAM-based, lost on reboot)"
write_separator
echo ""
printf "Press ENTER to close..."
read -r
