#!/bin/bash
# =============================================================
# update-truenas — TrueNAS SCALE/CORE maintenance script
# Requires: TrueNAS SCALE 22.x+ / TrueNAS CORE 13+
# Covers: apps (SCALE), plugins/jails (CORE), Docker, ZFS
# Run directly on TrueNAS via SSH
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

LOG_DIR="/root/logs/truenas"
LOG_FILE="$LOG_DIR/truenas-update.log"

detect_variant() {
    if [ -f /etc/version ] && grep -q "SCALE" /etc/version 2>/dev/null; then
        echo "SCALE"
    elif command -v midclt &>/dev/null; then
        echo "SCALE"
    elif [ -f /etc/version ]; then
        echo "CORE"
    else
        echo "UNKNOWN"
    fi
}

check_requirements() {
    local errors=0

    # Must be TrueNAS
    if [ ! -f /etc/version ] && ! command -v midclt &>/dev/null; then
        echo "ERROR: TrueNAS not detected."
        errors=$((errors + 1))
    fi

    local variant=$(detect_variant)

    # Version check
    if [ -f /etc/version ]; then
        if [ "$variant" = "SCALE" ]; then
            local ver=$(cat /etc/version | grep -oP '^\d+\.\d+' | head -1)
            local major=$(echo "$ver" | cut -d. -f1)
            if [ -n "$major" ] && [ "$major" -lt 22 ] 2>/dev/null; then
                echo "ERROR: TrueNAS SCALE 22.x or later required. Found: $(cat /etc/version)"
                errors=$((errors + 1))
            fi
        elif [ "$variant" = "CORE" ]; then
            local ver=$(cat /etc/version | grep -oP '^\d+' | head -1)
            if [ -n "$ver" ] && [ "$ver" -lt 13 ] 2>/dev/null; then
                echo "ERROR: TrueNAS CORE 13 or later required. Found: $(cat /etc/version)"
                errors=$((errors + 1))
            fi
        fi
    fi

    if [ "$variant" = "UNKNOWN" ]; then
        echo "ERROR: Could not determine TrueNAS variant (SCALE or CORE)."
        errors=$((errors + 1))
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

mkdir -p "$LOG_DIR"
check_requirements

VARIANT=$(detect_variant)

write_separator
write_log "🦈 TrueNAS $VARIANT update started - $(date)"
write_log "Version: $(cat /etc/version 2>/dev/null || echo 'unknown')"
write_separator

# SCALE — Apps (Kubernetes/k3s)
if [ "$VARIANT" = "SCALE" ]; then
    write_log ""
    write_log "📦 Checking TrueNAS SCALE apps..."
    if command -v midclt &>/dev/null; then
        write_log "📋 Installed apps:"
        midclt call chart.release.query 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for app in data:
        print(f\"  {app['name']}: {app['chart_metadata']['version']}\")
except:
    print('  Could not list apps')
" 2>/dev/null | tee -a "$LOG_FILE"
    fi
    write_log "ℹ️  Update apps via web interface: Apps → Installed → Update All"

    # Docker outside k3s
    write_log ""
    write_log "🐳 Checking Docker containers..."
    if command -v docker &>/dev/null; then
        docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" 2>&1 | tee -a "$LOG_FILE"
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

# CORE — Plugins/jails
if [ "$VARIANT" = "CORE" ]; then
    write_log ""
    write_log "📦 Checking TrueNAS CORE plugins/jails..."
    if command -v iocage &>/dev/null; then
        write_log "📋 Jails:"
        iocage list 2>&1 | tee -a "$LOG_FILE"
    else
        write_log "ℹ️  iocage not found."
    fi
    write_log "ℹ️  Update plugins via web interface: Plugins → Check for Updates"
fi

# ZFS pool status
write_log ""
write_log "🏊 ZFS pool status..."
if command -v zpool &>/dev/null; then
    zpool status 2>&1 | tee -a "$LOG_FILE"
else
    write_log "ℹ️  zpool not available."
fi

# Disk health
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
    write_log "ℹ️  Check disk health in web interface: Storage → Disks"
fi

# OS update
write_log ""
write_log "🔧 OS update check..."
write_log "ℹ️  Check for TrueNAS updates via web interface: System → Update"

write_log ""
write_separator
write_log "✅ All done! Log saved to $LOG_FILE"
write_separator
echo ""
echo "Press ENTER to close..."
read -r
