#!/bin/bash
# =============================================================
# update-qnap — QNAP NAS maintenance and update script
# Requires: QTS 4.5+ / QuTS hero h4.5+
# NOTE: bash may not exist on older QTS — use sh if needed
# Covers: Entware (opkg), Docker, firmware info, disk health
# Run directly on QNAP via SSH
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

LOG_DIR="/share/homes/admin/logs/qnap"
LOG_FILE="$LOG_DIR/qnap-update.log"

check_requirements() {
    local errors=0

    # Must be QNAP
    if [ ! -f /etc/version ] && [ ! -f /etc/qnap_fw.txt ]; then
        echo "ERROR: QNAP QTS not detected."
        errors=$((errors + 1))
    fi

    # Version check (require QTS 4.5+)
    if [ -f /etc/version ]; then
        local ver=$(cat /etc/version 2>/dev/null | grep -oP '^\d+\.\d+' | head -1)
        local major=$(echo "$ver" | cut -d. -f1)
        local minor=$(echo "$ver" | cut -d. -f2)
        if [ -n "$major" ]; then
            if [ "$major" -lt 4 ] 2>/dev/null || ([ "$major" -eq 4 ] && [ "$minor" -lt 5 ] 2>/dev/null); then
                echo "ERROR: QTS 4.5 or later required. Found: $ver"
                echo "       Please update QTS via the web interface first."
                errors=$((errors + 1))
            fi
        fi
    fi

    # Must run as admin/root
    if [ "$(id -u)" -ne 0 ]; then
        echo "ERROR: This script must be run as root or admin."
        errors=$((errors + 1))
    fi

    if [ "$errors" -gt 0 ]; then
        echo "Aborting due to $errors error(s)."
        exit 1
    fi
}

write_log() {
    local message="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

write_separator() {
    echo "============================================================" | tee -a "$LOG_FILE"
}

mkdir -p "$LOG_DIR" 2>/dev/null || {
    LOG_DIR="/tmp/logs/qnap"
    LOG_FILE="$LOG_DIR/qnap-update.log"
    mkdir -p "$LOG_DIR"
    echo "WARNING: Could not create log in /share/homes/admin — using /tmp instead"
}

check_requirements

write_separator
write_log "🗄️  QNAP update started - $(date)"
write_log "Model: $(uname -n) | Firmware: $(cat /etc/version 2>/dev/null || echo 'unknown')"
write_separator

# Entware (opkg)
write_log ""
write_log "📦 Checking Entware (opkg)..."
if command -v opkg &>/dev/null; then
    write_log "⬆️  Updating opkg package list..."
    opkg update 2>&1 | tee -a "$LOG_FILE"
    write_log "⬆️  Upgrading opkg packages..."
    opkg upgrade 2>&1 | tee -a "$LOG_FILE"
    write_log "✅ Entware packages updated."
else
    write_log "ℹ️  opkg (Entware) not found. Skipping."
    write_log "    Install Entware from QNAP App Center first."
fi

# Docker
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

# Firmware check
write_log ""
write_log "🔧 Firmware version: $(cat /etc/version 2>/dev/null || echo 'unknown')"
write_log "ℹ️  Check for firmware updates in QNAP QTS web interface:"
write_log "   Control Panel → System → Firmware Update"

# Disk health
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

write_log ""
write_separator
write_log "✅ All done! Log saved to $LOG_FILE"
write_separator
echo ""
echo "Press ENTER to close..."
read -r
