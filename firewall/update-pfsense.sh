#!/bin/sh
# =============================================================
# update-pfsense — pfSense firewall maintenance script
# Covers: pkg updates, firmware check, package updates
# Run directly on pfSense via SSH
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

LOG_DIR="/root/logs/pfsense"
LOG_FILE="$LOG_DIR/pfsense-update.log"

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
write_log "🔥 pfSense update started - $(date)"
write_log "📋 Version: $(cat /etc/version 2>/dev/null || echo 'unknown')"
write_log "📋 Hostname: $(hostname)"
write_separator

# =============================================================
# pkg packages
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
# pfSense packages
# =============================================================
write_log ""
write_log "🔌 Checking pfSense packages..."

if [ -f /usr/local/sbin/pkg_mgr_install.php ]; then
    write_log "📋 Installed packages:"
    php /usr/local/sbin/pkg_mgr_install.php list 2>/dev/null | tee -a "$LOG_FILE"
fi

write_log "ℹ️  Update packages via web interface: System → Package Manager → Installed Packages"

# =============================================================
# Firmware check
# =============================================================
write_log ""
write_log "🔧 Firmware update check..."
write_log "ℹ️  Check for pfSense updates via web interface:"
write_log "   System → Update → System Update"

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
