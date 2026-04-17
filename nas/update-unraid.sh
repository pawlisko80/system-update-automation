#!/bin/bash
# =============================================================
# update-unraid — Unraid maintenance and update script
# Covers: plugins, Docker containers, firmware check
# Run directly on Unraid via SSH or Unraid terminal
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

LOG_DIR="/boot/logs/unraid"
LOG_FILE="$LOG_DIR/unraid-update.log"

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
write_log "⚡ Unraid update started - $(date)"
write_log "📋 Version: $(cat /etc/unraid-version 2>/dev/null || echo 'unknown')"
write_separator

# =============================================================
# Slackware packages (underlying OS)
# =============================================================
write_log ""
write_log "📦 Checking Slackware packages..."

if command -v upgradepkg &>/dev/null; then
    write_log "ℹ️  Slackware packages on Unraid are managed by Unraid updates."
    write_log "    Use the Unraid web UI to update: Tools → Update OS"
else
    write_log "ℹ️  upgradepkg not found. Skipping."
fi

# =============================================================
# Community Applications / Plugins
# =============================================================
write_log ""
write_log "🔌 Plugin update check..."
write_log "ℹ️  Update plugins via Unraid web interface:"
write_log "   Plugins → Check for Updates"

if [ -d /var/log/plugins ]; then
    PLUGIN_COUNT=$(ls /var/log/plugins/*.plg 2>/dev/null | wc -l)
    write_log "📋 Installed plugins: $PLUGIN_COUNT"
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
    write_log "ℹ️  Docker not running. Start Docker service in Unraid settings."
fi

# =============================================================
# VMs check
# =============================================================
write_log ""
write_log "🖥️  VM status..."

if command -v virsh &>/dev/null; then
    write_log "📋 VM list:"
    virsh list --all 2>&1 | tee -a "$LOG_FILE"
else
    write_log "ℹ️  virsh not available. Check VMs in Unraid web interface."
fi

# =============================================================
# Array status
# =============================================================
write_log ""
write_log "💾 Array status..."

if [ -f /proc/mdstat ]; then
    cat /proc/mdstat | tee -a "$LOG_FILE"
fi

# =============================================================
# Disk health
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
    write_log "ℹ️  Check disk health in Unraid web interface: Main → Disk Health"
fi

# =============================================================
# OS update check
# =============================================================
write_log ""
write_log "🔧 OS update check..."
write_log "ℹ️  Check for Unraid OS updates in web interface:"
write_log "   Tools → Update OS"

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
