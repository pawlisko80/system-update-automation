#!/bin/bash
# =============================================================
# update-unraid — Unraid maintenance and update script
# Requires: Unraid 6.9+
# Covers: Docker containers, plugins, array/disk health
# Run directly on Unraid via SSH or Unraid terminal
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

LOG_DIR="/boot/logs/unraid"
LOG_FILE="$LOG_DIR/unraid-update.log"

check_requirements() {
    local errors=0

    # Must be Unraid
    if [ ! -f /etc/unraid-version ]; then
        echo "ERROR: Unraid not detected. /etc/unraid-version not found."
        errors=$((errors + 1))
    fi

    # Version check (require 6.9+)
    if [ -f /etc/unraid-version ]; then
        local ver=$(cat /etc/unraid-version | grep -oP 'version="\K[^"]+' | head -1)
        local major=$(echo "$ver" | cut -d. -f1)
        local minor=$(echo "$ver" | cut -d. -f2)
        if [ -n "$major" ]; then
            if [ "$major" -lt 6 ] 2>/dev/null || ([ "$major" -eq 6 ] && [ "$minor" -lt 9 ] 2>/dev/null); then
                echo "ERROR: Unraid 6.9 or later required. Found: $ver"
                echo "       Update via Tools → Update OS in the web interface."
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

# Try /boot/logs, fall back to /tmp
mkdir -p "$LOG_DIR" 2>/dev/null || {
    LOG_DIR="/tmp/logs/unraid"
    LOG_FILE="$LOG_DIR/unraid-update.log"
    mkdir -p "$LOG_DIR"
    echo "WARNING: Could not create log in /boot/logs — using /tmp instead"
}

check_requirements

write_separator
write_log "⚡ Unraid update started - $(date)"
write_log "Version: $(cat /etc/unraid-version 2>/dev/null | grep -oP 'version="\K[^"]+' || echo 'unknown')"
write_separator

# Docker containers
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

# Plugins
write_log ""
write_log "🔌 Plugin update check..."
if [ -d /var/log/plugins ]; then
    PLUGIN_COUNT=$(ls /var/log/plugins/*.plg 2>/dev/null | wc -l)
    write_log "📋 Installed plugins: $PLUGIN_COUNT"
fi
write_log "ℹ️  Update plugins via web interface: Plugins → Check for Updates"

# VMs
write_log ""
write_log "🖥️  VM status..."
if command -v virsh &>/dev/null; then
    write_log "📋 VM list:"
    virsh list --all 2>&1 | tee -a "$LOG_FILE"
else
    write_log "ℹ️  virsh not available. Check VMs in web interface."
fi

# Array status
write_log ""
write_log "💾 Array status..."
if [ -f /proc/mdstat ]; then
    cat /proc/mdstat | tee -a "$LOG_FILE"
fi

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
    write_log "ℹ️  Check disk health in web interface: Main → Disk Health"
fi

# OS update check
write_log ""
write_log "🔧 OS update check..."
write_log "ℹ️  Check for Unraid OS updates in web interface: Tools → Update OS"

write_log ""
write_separator
write_log "✅ All done! Log saved to $LOG_FILE"
write_separator
echo ""
echo "Press ENTER to close..."
read -r
