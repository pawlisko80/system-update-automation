#!/bin/sh
# =============================================================
# update-opnsense — OPNsense firewall maintenance script
# Requires: OPNsense 21.1+
# Covers: pkg updates, firmware check, plugin updates, WireGuard
# Run directly on OPNsense via SSH
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

LOG_DIR="/root/logs/opnsense"
LOG_FILE="$LOG_DIR/opnsense-update.log"

check_requirements() {
    local errors=0

    # Must be OPNsense
    if ! command -v opnsense-version >/dev/null 2>&1 && [ ! -f /usr/local/opnsense/version/opnsense ]; then
        echo "ERROR: OPNsense not detected. Is this an OPNsense host?"
        errors=$((errors + 1))
    fi

    # Version check (require 21.1+)
    if command -v opnsense-version >/dev/null 2>&1; then
        local ver=$(opnsense-version -v 2>/dev/null | grep -oP '^\d+' | head -1)
        if [ -n "$ver" ] && [ "$ver" -lt 21 ] 2>/dev/null; then
            echo "ERROR: OPNsense 21.1 or later required. Found: $(opnsense-version -v 2>/dev/null)"
            errors=$((errors + 1))
        fi
    fi

    # Must run as root
    if [ "$(id -u)" -ne 0 ]; then
        echo "ERROR: This script must be run as root."
        errors=$((errors + 1))
    fi

    # pkg required
    if ! command -v pkg >/dev/null 2>&1; then
        echo "ERROR: pkg not found."
        errors=$((errors + 1))
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
write_log "🔥 OPNsense update started - $(date)"
write_log "Version: $(opnsense-version 2>/dev/null || cat /usr/local/opnsense/version/opnsense 2>/dev/null || echo 'unknown')"
write_log "Hostname: $(hostname)"
write_separator

# pkg packages
write_log ""
write_log "📦 Updating pkg packages..."
pkg update 2>&1 | tee -a "$LOG_FILE"
pkg upgrade -y 2>&1 | tee -a "$LOG_FILE"
write_log "✅ pkg update complete."

# OPNsense firmware
write_log ""
write_log "🔧 Checking OPNsense firmware updates..."
if command -v opnsense-update >/dev/null 2>&1; then
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

# Plugins
write_log ""
write_log "🔌 Installed plugins:"
pkg query -e '%#r > 0' '%n %v' 2>/dev/null | grep "^os-" | tee -a "$LOG_FILE"
write_log "ℹ️  Update plugins via web interface: System → Firmware → Plugins"

# WireGuard status
write_log ""
write_log "🔐 WireGuard tunnel status..."
if command -v wg >/dev/null 2>&1; then
    wg show 2>&1 | tee -a "$LOG_FILE"
else
    write_log "ℹ️  WireGuard not running or not installed."
fi

# Interface summary
write_log ""
write_log "🌐 Interface summary..."
ifconfig | grep -E "^[a-z]|inet " | tee -a "$LOG_FILE"

write_log ""
write_separator
write_log "✅ All done! Log saved to $LOG_FILE"
write_separator
echo ""
printf "Press ENTER to close..."
read -r
