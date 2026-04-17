#!/bin/sh
# =============================================================
# update-alpine — Alpine Linux maintenance script
# Covers: apk packages, firmware (if applicable)
# Used in: Docker containers, VMs, edge devices, routers
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

LOG_DIR="$HOME/logs/alpine"
LOG_FILE="$LOG_DIR/alpine-update.log"

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
write_log "🏔️  Alpine Linux update started - $(date)"
write_log "📋 Version: $(cat /etc/alpine-release 2>/dev/null || echo 'unknown')"
write_log "📋 Kernel: $(uname -r)"
write_separator

# =============================================================
# apk update & upgrade
# =============================================================
write_log ""
write_log "📦 Updating apk packages..."
apk update 2>&1 | tee -a "$LOG_FILE"

write_log ""
write_log "⬆️  Upgrading packages..."
apk upgrade 2>&1 | tee -a "$LOG_FILE"
write_log "✅ apk update complete."

# =============================================================
# Cache cleanup
# =============================================================
write_log ""
write_log "🧹 Cleaning apk cache..."
apk cache clean 2>&1 | tee -a "$LOG_FILE"
write_log "✅ Cache cleaned."

# =============================================================
# Reboot check (kernel updates)
# =============================================================
write_log ""
CURRENT_KERNEL=$(uname -r)
INSTALLED_KERNEL=$(apk info -e linux-lts 2>/dev/null && apk info linux-lts 2>/dev/null | grep -i "linux-lts-" | head -1 | awk '{print $1}' || echo "unknown")
write_log "📋 Running kernel: $CURRENT_KERNEL"
write_log "ℹ️  If kernel was updated, reboot to apply: reboot"

# =============================================================
# Done
# =============================================================
write_log ""
write_separator
write_log "✅ All done! Log saved to $LOG_FILE"
write_separator
echo ""
printf "Press ENTER to close..."
read -r
