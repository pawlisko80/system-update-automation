#!/bin/bash
# =============================================================
# update-synology — Synology NAS maintenance and update script
# Covers: ipkg/opkg (Entware), Docker, firmware check
# Run directly on Synology via SSH
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

LOG_DIR="/volume1/homes/admin/logs/synology"
LOG_FILE="$LOG_DIR/synology-update.log"

mkdir -p "$LOG_DIR"

write_log() {
    local message="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

write_separator() {
    echo "============================================================" | tee -a "$LOG_FILE"
}

write_separator
write_log "🗄️  Synology update started - $(date)"
write_log "📋 Model: $(cat /proc/sys/kernel/syno_hw_version 2>/dev/null || uname -n)"
write_log "📋 DSM: $(cat /etc/VERSION 2>/dev/null | grep productversion | cut -d'"' -f2 || echo 'unknown')"
write_separator

# =============================================================
# Entware (opkg)
# =============================================================
write_log ""
write_log "📦 Checking Entware (opkg)..."

if command -v opkg &>/dev/null; then
    write_log "⬆️  Updating opkg package list..."
    opkg update 2>&1 | tee -a "$LOG_FILE"
    write_log "⬆️  Upgrading opkg packages..."
    opkg upgrade 2>&1 | tee -a "$LOG_FILE"
    write_log "✅ Entware packages updated."
elif command -v ipkg &>/dev/null; then
    write_log "⬆️  Updating ipkg packages (legacy)..."
    ipkg update 2>&1 | tee -a "$LOG_FILE"
    ipkg upgrade 2>&1 | tee -a "$LOG_FILE"
    write_log "✅ ipkg packages updated."
else
    write_log "⚠️  Neither opkg nor ipkg found. Skipping."
    write_log "    Install Entware from Synology Package Center."
fi

# =============================================================
# Docker containers
# =============================================================
write_log ""
write_log "🐳 Checking Docker containers..."

if command -v docker &>/dev/null; then
    write_log "📋 Running containers:"
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" 2>&1 | tee -a "$LOG_FILE"

    write_log ""
    write_log "⬆️  Pulling latest images for running containers..."
    docker ps --format "{{.Image}}" | sort -u | while read -r image; do
        write_log "   Pulling: $image"
        docker pull "$image" 2>&1 | tee -a "$LOG_FILE"
    done

    write_log ""
    write_log "🧹 Removing unused Docker images..."
    docker image prune -f 2>&1 | tee -a "$LOG_FILE"
    write_log "✅ Docker update complete."
else
    write_log "ℹ️  Docker not found. Skipping Container Manager update."
fi

# =============================================================
# DSM firmware check (informational only)
# =============================================================
write_log ""
write_log "🔧 Firmware update check..."
write_log "ℹ️  Check for DSM updates in Synology web interface:"
write_log "   Control Panel → Update & Restore → DSM Update"

# =============================================================
# Package Center updates via synopkg
# =============================================================
write_log ""
write_log "📦 Checking Synology packages..."

if command -v synopkg &>/dev/null; then
    write_log "📋 Installed packages:"
    synopkg list 2>&1 | tee -a "$LOG_FILE"
    write_log "ℹ️  Update packages via Package Center in DSM web interface."
else
    write_log "ℹ️  synopkg not available via SSH. Update packages via DSM web interface."
fi

# =============================================================
# Disk health check
# =============================================================
write_log ""
write_log "💾 Disk health summary..."

if command -v smartctl &>/dev/null; then
    for disk in /dev/sd[a-z]; do
        if [ -b "$disk" ]; then
            STATUS=$(smartctl -H "$disk" 2>/dev/null | grep "overall-health" | awk '{print $NF}')
            write_log "   $disk: ${STATUS:-unknown}"
        fi
    done
else
    write_log "ℹ️  Check disk health in DSM Storage Manager → HDD/SSD."
fi

# =============================================================
# Done
# =============================================================
write_log ""
write_separator
write_log "✅ All done! Log saved to $LOG_FILE"
write_separator
echo ""
echo "Press ENTER to close..."
read -r
