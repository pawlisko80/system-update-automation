#!/bin/bash
# =============================================================
# update-qnap — QNAP NAS maintenance and update script
# Covers: opkg packages, Container Station (Docker), firmware check
# Run directly on QNAP via SSH
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

LOG_DIR="/share/homes/admin/logs/qnap"
LOG_FILE="$LOG_DIR/qnap-update.log"

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
write_log "🗄️  QNAP update started - $(date)"
write_log "📋 Model: $(uname -n) | Firmware: $(cat /etc/version 2>/dev/null || echo 'unknown')"
write_separator

# =============================================================
# opkg packages (Entware)
# =============================================================
write_log ""
write_log "📦 Checking Entware (opkg)..."

if command -v opkg &>/dev/null; then
    write_log "⬆️  Updating opkg package list..."
    opkg update 2>&1 | tee -a "$LOG_FILE"
    write_log "⬆️  Upgrading opkg packages..."
    opkg upgrade 2>&1 | tee -a "$LOG_FILE"
    write_log "✅ Entware packages updated."
else
    write_log "⚠️  opkg (Entware) not found. Skipping."
    write_log "    Install Entware from QNAP App Center first."
fi

# =============================================================
# Docker containers (Container Station)
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
    write_log "ℹ️  Docker not found. Skipping Container Station update."
fi

# =============================================================
# Firmware check (informational only)
# =============================================================
write_log ""
write_log "🔧 Checking firmware version..."
CURRENT_FW=$(cat /etc/version 2>/dev/null || echo "unknown")
write_log "   Current firmware: $CURRENT_FW"
write_log "ℹ️  Check for firmware updates in QNAP QTS web interface:"
write_log "   Control Panel → System → Firmware Update"

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
    write_log "ℹ️  smartctl not available. Check disk health in QTS Storage Manager."
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
