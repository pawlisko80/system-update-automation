#!/bin/sh
# =============================================================
# update-openwrt — OpenWrt router maintenance script
# Requires: OpenWrt 19.07+
# Covers: opkg packages, config backup, firmware info
# Run directly on OpenWrt via SSH (ash shell)
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

LOG_DIR="/tmp/logs/openwrt"
LOG_FILE="$LOG_DIR/openwrt-update.log"

check_requirements() {
    errors=0

    # Must be OpenWrt
    if [ ! -f /etc/openwrt_release ]; then
        echo "ERROR: OpenWrt not detected. /etc/openwrt_release not found."
        errors=$((errors + 1))
    fi

    # Must have opkg
    if ! command -v opkg >/dev/null 2>&1; then
        echo "ERROR: opkg not found."
        errors=$((errors + 1))
    fi

    # Version check (require 19.07+)
    if [ -f /etc/openwrt_release ]; then
        ver=$(grep DISTRIB_RELEASE /etc/openwrt_release | cut -d'=' -f2 | tr -d '"' | cut -d. -f1)
        if [ -n "$ver" ] && [ "$ver" != "SNAPSHOT" ]; then
            if [ "$ver" -lt 19 ] 2>/dev/null; then
                echo "ERROR: OpenWrt 19.07 or later required. Found: $ver"
                echo "       Please update via LuCI: System → Backup/Flash Firmware"
                errors=$((errors + 1))
            fi
        fi
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

CURRENT_VER=$(grep DISTRIB_RELEASE /etc/openwrt_release 2>/dev/null | cut -d'=' -f2 | tr -d '"')
CURRENT_TARGET=$(grep DISTRIB_TARGET /etc/openwrt_release 2>/dev/null | cut -d'=' -f2 | tr -d '"')

write_separator
write_log "📡 OpenWrt update started - $(date)"
write_log "Version: ${CURRENT_VER:-unknown} | Target: ${CURRENT_TARGET:-unknown}"
write_log "Model: $(cat /tmp/sysinfo/model 2>/dev/null || echo 'unknown')"
write_separator

write_log ""
write_log "⚠️  NOTE: OpenWrt overlay filesystem has limited space."
write_log "    Only install essential packages to avoid running out of space."

# opkg packages
write_log ""
write_log "📦 Updating opkg packages..."
opkg update 2>&1 | tee -a "$LOG_FILE"

write_log "📋 Checking for upgradable packages..."
UPGRADABLE=$(opkg list-upgradable 2>/dev/null)
if [ -n "$UPGRADABLE" ]; then
    echo "$UPGRADABLE" | tee -a "$LOG_FILE"
    write_log "⚠️  Upgradable packages found!"
    printf "Upgrade all packages? Note: kernel packages may require reboot (y/N): "
    read -r REPLY
    if [ "$REPLY" = "y" ] || [ "$REPLY" = "Y" ]; then
        write_log "⬆️  Upgrading packages..."
        opkg list-upgradable | cut -f1 -d' ' | xargs opkg upgrade 2>&1 | tee -a "$LOG_FILE"
        write_log "✅ Package upgrade complete."
    else
        write_log "⏭️  Skipping package upgrade."
    fi
else
    write_log "✅ All packages are up to date."
fi

# Config backup
write_log ""
write_log "💾 Creating config backup..."
BACKUP_FILE="/tmp/openwrt-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
if command -v sysupgrade >/dev/null 2>&1; then
    sysupgrade -b "$BACKUP_FILE" 2>&1 | tee -a "$LOG_FILE"
    write_log "✅ Config backed up to $BACKUP_FILE"
    write_log "ℹ️  Copy backup off-device: scp root@router:$BACKUP_FILE ./"
else
    write_log "ℹ️  sysupgrade not found — skipping config backup."
fi

# Firmware info
write_log ""
write_log "🔧 Firmware info..."
write_log "   Current: ${CURRENT_VER:-unknown} (${CURRENT_TARGET:-unknown})"
write_log "ℹ️  Check for OpenWrt updates at: https://firmware-selector.openwrt.org/"
write_log "ℹ️  Or via LuCI: System → Backup/Flash Firmware"

# Resources
write_log ""
write_log "💻 System resources..."
write_log "   Memory:"
free 2>/dev/null | tee -a "$LOG_FILE"
write_log "   Storage:"
df -h 2>/dev/null | tee -a "$LOG_FILE"

write_log ""
write_log "⚠️  NOTE: Logs in /tmp are RAM-based and will be lost on reboot."
write_separator
write_log "✅ All done! Log saved to $LOG_FILE"
write_separator
echo ""
printf "Press ENTER to close..."
read -r
