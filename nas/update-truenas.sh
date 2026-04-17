#!/bin/bash
# =============================================================
# update-truenas — TrueNAS SCALE/CORE maintenance script
# Covers: apps (SCALE), plugins (CORE), Docker/k3s, firmware check
# Run directly on TrueNAS via SSH
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

LOG_DIR="/root/logs/truenas"
LOG_FILE="$LOG_DIR/truenas-update.log"

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

# Detect TrueNAS variant
detect_variant() {
    if [ -f /etc/version ] && grep -q "SCALE" /etc/version 2>/dev/null; then
        echo "SCALE"
    elif command -v midclt &>/dev/null; then
        echo "SCALE"
    else
        echo "CORE"
    fi
}

VARIANT=$(detect_variant)

write_separator
write_log "🦈 TrueNAS $VARIANT update started - $(date)"
write_log "📋 Version: $(cat /etc/version 2>/dev/null || echo 'unknown')"
write_separator

# =============================================================
# TrueNAS SCALE — Apps (Kubernetes/k3s)
# =============================================================
if [ "$VARIANT" = "SCALE" ]; then
    write_log ""
    write_log "📦 Checking TrueNAS SCALE apps..."

    if command -v midclt &>/dev/null; then
        write_log "📋 Installed apps:"
        midclt call chart.release.query 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
for app in data:
    print(f\"  {app['name']}: {app['chart_metadata']['version']}\")
" 2>/dev/null | tee -a "$LOG_FILE" || write_log "ℹ️  Could not list apps via midclt."

        write_log ""
        write_log "ℹ️  Update apps via TrueNAS web interface:"
        write_log "   Apps → Installed Applications → Update All"
    fi

    # Docker (if installed outside of k3s)
    write_log ""
    write_log "🐳 Checking Docker containers..."
    if command -v docker &>/dev/null; then
        write_log "📋 Running containers:"
        docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" 2>&1 | tee -a "$LOG_FILE"

        write_log "⬆️  Pulling latest images..."
        docker ps --format "{{.Image}}" | sort -u | while read -r image; do
            write_log "   Pulling: $image"
            docker pull "$image" 2>&1 | tee -a "$LOG_FILE"
        done

        docker image prune -f 2>&1 | tee -a "$LOG_FILE"
        write_log "✅ Docker update complete."
    else
        write_log "ℹ️  Docker not found outside k3s. Manage containers via TrueNAS Apps."
    fi
fi

# =============================================================
# TrueNAS CORE — Plugins (jails)
# =============================================================
if [ "$VARIANT" = "CORE" ]; then
    write_log ""
    write_log "📦 Checking TrueNAS CORE plugins/jails..."

    if command -v iocage &>/dev/null; then
        write_log "📋 Jails:"
        iocage list 2>&1 | tee -a "$LOG_FILE"
        write_log ""
        write_log "ℹ️  Update plugins via TrueNAS web interface:"
        write_log "   Plugins → Check for Updates"
    else
        write_log "ℹ️  iocage not found. Check plugins via TrueNAS web interface."
    fi
fi

# =============================================================
# Pool status
# =============================================================
write_log ""
write_log "🏊 ZFS pool status..."

if command -v zpool &>/dev/null; then
    zpool status 2>&1 | tee -a "$LOG_FILE"
else
    write_log "ℹ️  zpool not available."
fi

# =============================================================
# Disk health
# =============================================================
write_log ""
write_log "💾 Disk health summary..."

if command -v smartctl &>/dev/null; then
    for disk in /dev/sd[a-z] /dev/nvme[0-9]n[0-9]; do
        if [ -b "$disk" ]; then
            STATUS=$(smartctl -H "$disk" 2>/dev/null | grep "overall-health\|result:" | awk '{print $NF}')
            write_log "   $disk: ${STATUS:-unknown}"
        fi
    done
else
    write_log "ℹ️  Check disk health in TrueNAS web interface: Storage → Disks"
fi

# =============================================================
# OS update check
# =============================================================
write_log ""
write_log "🔧 OS update check..."
write_log "ℹ️  Check for TrueNAS updates in web interface:"
write_log "   System → Update"

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
