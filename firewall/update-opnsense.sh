#!/bin/sh
# =============================================================
# update-opnsense — OPNsense firewall maintenance script
# Covers: pkg updates, firmware check, plugin updates
# Run directly on OPNsense via SSH
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

LOG_DIR="/root/logs/opnsense"
LOG_FILE="$LOG_DIR/opnsense-update.log"

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
write_log "🔥 OPNsense update started - $(date)"
write_log "📋 Version: $(opnsense-version 2>/dev/null || cat /usr/local/opnsense/version/opnsense 2>/dev/null || echo 'unknown')"
write_log "📋 Hostname: $(hostname)"
write_separator

# =============================================================
# pkg packages (FreeBSD base)
# =============================================================
write_log ""
write_log "📦 Updating pkg packages..."

if command -v pkg >/dev/null 2>&1; then
    pkg update 2>&1 | tee -a "$LOG_FILE"
    pkg upgrade -y 2>&1 | tee -a "$LOG_FILE"
    write_log "✅ pkg update complete."
else
    write_log "❌ pkg not found. Skipping."
fi

# =============================================================
# OPNsense firmware/core update
# =============================================================
write_log ""
write_log "🔧 Checking OPNsense firmware updates..."

if command -v opnsense-update >/dev/null 2>&1; then
    write_log "📋 Checking for updates..."
    UPDATE_OUTPUT=$(opnsense-update -c 2>&1)
    echo "$UPDATE_OUTPUT" | tee -a "$LOG_FILE"

    if echo "$UPDATE_OUTPUT" | grep -q "Please reboot"; then
        write_log "⚠️  Updates available!"
        printf "Install OPNsense firmware update? (y/N): "
        read -r REPLY
        if [ "$REPLY" = "y" ] || [ "$REPLY" = "Y" ]; then
            write_log "⬆️  Installing firmware updates..."
            opnsense-update -u 2>&1 | tee -a "$LOG_FILE"
            write_log "✅ Firmware updated. Reboot required."
            write_log "ℹ️  Reboot via: reboot"
        else
            write_log "⏭️  Skipping firmware update."
        fi
    else
        write_log "✅ OPNsense firmware is up to date."
    fi
else
    write_log "ℹ️  opnsense-update not found."
    write_log "    Update via web interface: System → Firmware → Updates"
fi

# =============================================================
# OPNsense plugins
# =============================================================
write_log ""
write_log "🔌 Checking OPNsense plugins..."

if command -v opnsense-update >/dev/null 2>&1; then
    write_log "📋 Installed plugins:"
    pkg query -e '%#r > 0' '%n %v' 2>/dev/null | grep "os-" | tee -a "$LOG_FILE"
    write_log "ℹ️  Update plugins via web interface: System → Firmware → Plugins"
fi

# =============================================================
# WireGuard status
# =============================================================
write_log ""
write_log "🔐 WireGuard tunnel status..."

if command -v wg >/dev/null 2>&1; then
    wg show 2>&1 | tee -a "$LOG_FILE"
else
    write_log "ℹ️  WireGuard not found or not running."
fi

# =============================================================
# Interface status
# =============================================================
write_log ""
write_log "🌐 Interface summary..."
ifconfig | grep -E "^[a-z]|inet " | tee -a "$LOG_FILE"

# =============================================================
# Done
# =============================================================
write_log ""
write_separator
write_log "✅ All done! Log saved to $LOG_FILE"
write_separator
echo ""
printf "Press ENTER to close..."
read -r
