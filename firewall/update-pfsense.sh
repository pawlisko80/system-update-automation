#!/bin/sh
# =============================================================
# update-pfsense — pfSense firewall maintenance script
# Requires: pfSense 2.5+
# Covers: pkg updates, package info, firmware check
# Run directly on pfSense via SSH
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

LOG_DIR="/root/logs/pfsense"
LOG_FILE="$LOG_DIR/pfsense-update.log"

check_requirements() {
    errors=0

    # Must be pfSense
    if [ ! -f /etc/version ] || ! grep -q "pfSense" /etc/version 2>/dev/null; then
        if [ ! -f /etc/platform ] || ! grep -q "pfSense\|pfsense" /etc/platform 2>/dev/null; then
            echo "ERROR: pfSense not detected."
            errors=$((errors + 1))
        fi
    fi

    # Version check (require 2.5+)
    if [ -f /etc/version ]; then
        ver=$(cat /etc/version | grep -oP '^\d+\.\d+' | head -1)
        major=$(echo "$ver" | cut -d. -f1)
        minor=$(echo "$ver" | cut -d. -f2)
        if [ -n "$major" ]; then
            if [ "$major" -lt 2 ] 2>/dev/null || ([ "$major" -eq 2 ] && [ "$minor" -lt 5 ] 2>/dev/null); then
                echo "ERROR: pfSense 2.5 or later required. Found: $ver"
                echo "       Update via System → Update → System Update in the web interface."
                errors=$((errors + 1))
            fi
        fi
    fi

    # Must run as root
    if [ "$(id -u)" -ne 0 ]; then
        echo "ERROR: This script must be run as root."
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
write_log "🔥 pfSense update started - $(date)"
write_log "Version: $(cat /etc/version 2>/dev/null || echo 'unknown')"
write_log "Hostname: $(hostname)"
write_separator

# pkg packages
write_log ""
write_log "📦 Updating pkg packages..."
if command -v pkg >/dev/null 2>&1; then
    pkg update 2>&1 | tee -a "$LOG_FILE"
    pkg upgrade -y 2>&1 | tee -a "$LOG_FILE"
    write_log "✅ pkg update complete."
else
    write_log "❌ pkg not found. Skipping."
fi

# pfSense packages
write_log ""
write_log "🔌 Checking pfSense packages..."
if [ -f /usr/local/sbin/pkg_mgr_install.php ]; then
    write_log "📋 Installed packages:"
    php /usr/local/sbin/pkg_mgr_install.php list 2>/dev/null | tee -a "$LOG_FILE" || \
        write_log "ℹ️  Could not list packages via CLI."
fi
write_log "ℹ️  Update packages via web interface: System → Package Manager → Installed"

# Firmware check
write_log ""
write_log "🔧 Firmware update check..."
write_log "ℹ️  Check for pfSense updates via web interface:"
write_log "   System → Update → System Update"

# Interface status
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
