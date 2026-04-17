#!/bin/sh
# =============================================================
# update-openwrt — OpenWrt router maintenance script
# Covers: opkg packages, firmware check, luci packages
# Run directly on OpenWrt via SSH (ash shell)
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

LOG_DIR="/tmp/logs/openwrt"
LOG_FILE="$LOG_DIR/openwrt-update.log"

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
write_log "📡 OpenWrt update started - $(date)"
write_log "📋 Version: $(cat /etc/openwrt_release 2>/dev/null | grep DISTRIB_RELEASE | cut -d'=' -f2 | tr -d '"' || echo 'unknown')"
write_log "📋 Model: $(cat /tmp/sysinfo/model 2>/dev/null || echo 'unknown')"
write_log "📋 Hostname: $(uci get system.@system[0].hostname 2>/dev/null || hostname)"
write_separator

write_log ""
write_log "⚠️  NOTE: OpenWrt overlay filesystem has limited space."
write_log "    Only install essential packages to avoid running out of space."

# =============================================================
# opkg packages
# =============================================================
write_log ""
write_log "📦 Updating opkg packages..."

if command -v opkg >/dev/null 2>&1; then
    write_log "⬆️  Updating package list..."
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
else
    write_log "❌ opkg not found. Skipping."
fi

# =============================================================
# Firmware/sysupgrade check
# =============================================================
write_log ""
write_log "🔧 Firmware information..."
CURRENT_VER=$(cat /etc/openwrt_release 2>/dev/null | grep DISTRIB_RELEASE | cut -d'=' -f2 | tr -d '"')
CURRENT_TARGET=$(cat /etc/openwrt_release 2>/dev/null | grep DISTRIB_TARGET | cut -d'=' -f2 | tr -d '"')
write_log "   Current version: ${CURRENT_VER:-unknown}"
write_log "   Target/arch: ${CURRENT_TARGET:-unknown}"
write_log "ℹ️  Check for OpenWrt firmware updates at:"
write_log "   https://firmware-selector.openwrt.org/"
write_log "   Or via LuCI: System → Backup/Flash Firmware"
write_log "⚠️  Always backup config before sysupgrade:"
write_log "   sysupgrade -b /tmp/backup-\$(date +%Y%m%d).tar.gz"

# =============================================================
# UCI config backup
# =============================================================
write_log ""
write_log "💾 Creating config backup..."
BACKUP_FILE="/tmp/openwrt-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
sysupgrade -b "$BACKUP_FILE" 2>&1 | tee -a "$LOG_FILE"
write_log "✅ Config backed up to $BACKUP_FILE"
write_log "ℹ️  Copy backup off-device: scp root@router:/tmp/openwrt-backup*.tar.gz ./"

# =============================================================
# Network status
# =============================================================
write_log ""
write_log "🌐 Network status..."
ifconfig 2>/dev/null | grep -E "^[a-z]|inet addr" | tee -a "$LOG_FILE"

# =============================================================
# WAN status
# =============================================================
write_log ""
write_log "🌐 WAN status..."
WAN_IP=$(uci get network.wan.ipaddr 2>/dev/null || ip addr show eth1 2>/dev/null | grep "inet " | awk '{print $2}')
write_log "   WAN IP: ${WAN_IP:-check with: ip addr show}"

# =============================================================
# System resources
# =============================================================
write_log ""
write_log "💻 System resources..."
write_log "   Memory:"
free 2>/dev/null | tee -a "$LOG_FILE"
write_log "   Storage:"
df -h 2>/dev/null | tee -a "$LOG_FILE"

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
