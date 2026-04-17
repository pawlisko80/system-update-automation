#!/bin/bash
# =============================================================
# update-synology — Synology NAS maintenance and update script
# Requires: DSM 6.2+
# Covers: Entware (opkg/ipkg), Docker, firmware info, disk health
# Run directly on Synology via SSH
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

LOG_DIR="/volume1/homes/admin/logs/synology"
LOG_FILE="$LOG_DIR/synology-update.log"

check_requirements() {
    local errors=0

    # Must be Synology DSM
    if [ ! -f /etc/synoinfo.conf ] && [ ! -f /etc/VERSION ]; then
        echo "ERROR: Synology DSM not detected."
        errors=$((errors + 1))
    fi

    # Version check (require DSM 6.2+)
    if [ -f /etc/VERSION ]; then
        local major=$(grep "^majorversion=" /etc/VERSION | cut -d'"' -f2)
        local minor=$(grep "^minorversion=" /etc/VERSION | cut -d'"' -f2)
        if [ -n "$major" ]; then
            if [ "$major" -lt 6 ] 2>/dev/null || ([ "$major" -eq 6 ] && [ "$minor" -lt 2 ] 2>/dev/null); then
                echo "ERROR: DSM 6.2 or later required. Found: DSM $major.$minor"
                echo "       Please update DSM via Control Panel → Update & Restore first."
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
    local message="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

write_separator() {
    echo "============================================================" | tee -a "$LOG_FILE"
}

# Try default log location, fall back to /tmp
mkdir -p "$LOG_DIR" 2>/dev/null || {
    LOG_DIR="/tmp/logs/synology"
    LOG_FILE="$LOG_DIR/synology-update.log"
    mkdir -p "$LOG_DIR"
    echo "WARNING: Could not create log in /volume1/homes/admin — using /tmp instead"
}

check_requirements

DSM_VER=$(grep "^productversion=" /etc/VERSION 2>/dev/null | cut -d'"' -f2 || echo "unknown")

write_separator
write_log "🗄️  Synology update started - $(date)"
write_log "Model: $(cat /proc/sys/kernel/syno_hw_version 2>/dev/null || uname -n)"
write_log "DSM: $DSM_VER"
write_separator

# Entware
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
    write_log "ℹ️  Neither opkg nor ipkg found. Skipping."
    write_log "    Install Entware from Synology Package Center."
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
    write_log "ℹ️  Docker not found. Skipping Container Manager update."
fi

# DSM firmware
write_log ""
write_log "🔧 DSM firmware update check..."
write_log "ℹ️  Check for DSM updates via web interface:"
write_log "   Control Panel → Update & Restore → DSM Update"

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
    write_log "ℹ️  Check disk health in DSM Storage Manager → HDD/SSD."
fi

write_log ""
write_separator
write_log "✅ All done! Log saved to $LOG_FILE"
write_separator
echo ""
echo "Press ENTER to close..."
read -r
