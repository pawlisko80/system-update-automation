#!/bin/sh
# =============================================================
# update-ddwrt — DD-WRT router maintenance script
# Requires: DD-WRT with BusyBox and nvram command
# NOTE: Logs stored in RAM (/tmp) — lost on reboot
#       Mount USB drive and change LOG_DIR for persistence
# Covers: Entware/Optware packages, NVRAM info, WAN status
# Run directly on DD-WRT via SSH (BusyBox/ash shell)
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

LOG_DIR="/tmp/logs/ddwrt"
LOG_FILE="$LOG_DIR/ddwrt-update.log"

check_requirements() {
    errors=0

    # Must have nvram (DD-WRT specific)
    if ! command -v nvram >/dev/null 2>&1; then
        echo "ERROR: nvram command not found. Is this a DD-WRT device?"
        errors=$((errors + 1))
    fi

    # Must have BusyBox
    if ! command -v busybox >/dev/null 2>&1; then
        echo "WARNING: busybox not found — some features may not work."
    fi

    # Check for DD-WRT specific files
    if [ ! -f /tmp/loginprompt ] && ! nvram get dd_version >/dev/null 2>&1; then
        echo "WARNING: Could not verify DD-WRT version. Proceeding anyway."
    fi

    if [ "$errors" -gt 0 ]; then
        echo "Aborting due to $errors error(s)."
        exit 1
    fi
}

write_log() {
    message="$1"
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

write_separator() {
    echo "============================================================" | tee -a "$LOG_FILE"
}

mkdir -p "$LOG_DIR"
check_requirements

write_separator
write_log "📡 DD-WRT update started - $(date)"
write_log "Version: $(nvram get dd_version 2>/dev/null || nvram get os_version 2>/dev/null || echo 'unknown')"
write_log "Model: $(nvram get DD_BOARD 2>/dev/null || nvram get board_name 2>/dev/null || echo 'unknown')"
write_log "Hostname: $(nvram get wan_hostname 2>/dev/null || hostname)"
write_separator

write_log ""
write_log "⚠️  NOTE: DD-WRT logs in /tmp are RAM-based and lost on reboot."
write_log "    For persistent logs, mount USB and change LOG_DIR in this script."

# Entware/Optware packages
write_log ""
write_log "📦 Checking Entware/Optware packages..."
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

# NVRAM info
write_log ""
write_log "💾 NVRAM info..."
NVRAM_USED=$(nvram show 2>/dev/null | grep "size:" | awk '{print $2}')
write_log "   NVRAM usage: ${NVRAM_USED:-unknown}"

# Firmware check
write_log ""
write_log "🔧 Firmware information..."
CURRENT_VER=$(nvram get dd_version 2>/dev/null || nvram get os_version 2>/dev/null || echo "unknown")
write_log "   Current version: $CURRENT_VER"
write_log "ℹ️  Check for DD-WRT firmware updates at:"
write_log "   https://dd-wrt.com/support/router-database/"
write_log "   Web UI: Administration → Firmware Upgrade"
write_log "⚠️  Always back up NVRAM before flashing:"
write_log "   Administration → Backup → NVRAM Backup"

# WAN status
write_log ""
write_log "🌐 WAN status..."
WAN_IP=$(nvram get wan_ipaddr 2>/dev/null)
WAN_GW=$(nvram get wan_gateway 2>/dev/null)
write_log "   WAN IP: ${WAN_IP:-unknown}"
write_log "   Gateway: ${WAN_GW:-unknown}"

# Interface summary
write_log ""
write_log "🌐 Network interfaces..."
ifconfig 2>/dev/null | grep -E "^[a-z]|inet addr" | tee -a "$LOG_FILE"

write_log ""
write_separator
write_log "✅ All done! Log saved to $LOG_FILE (RAM-based, lost on reboot)"
write_separator
echo ""
printf "Press ENTER to close..."
read -r
