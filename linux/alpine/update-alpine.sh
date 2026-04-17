#!/bin/sh
# =============================================================
# update-alpine — Alpine Linux maintenance script
# Requires: Alpine Linux 3.12+
# Covers: apk packages, cache cleanup
# Used in: Docker containers, VMs, edge devices, routers
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

LOG_DIR="$HOME/logs/alpine"
LOG_FILE="$LOG_DIR/alpine-update.log"

check_requirements() {
    errors=0

    # Must have apk
    if ! command -v apk >/dev/null 2>&1; then
        echo "ERROR: apk not found. This script requires Alpine Linux."
        errors=$((errors + 1))
    fi

    # Version check (require 3.12+)
    if [ -f /etc/alpine-release ]; then
        ver=$(cat /etc/alpine-release)
        major=$(echo "$ver" | cut -d. -f1)
        minor=$(echo "$ver" | cut -d. -f2)
        if [ "$major" -lt 3 ] 2>/dev/null || ([ "$major" -eq 3 ] && [ "$minor" -lt 12 ] 2>/dev/null); then
            echo "ERROR: Alpine Linux 3.12 or later required. Found: $ver"
            errors=$((errors + 1))
        fi
    else
        echo "WARNING: Cannot determine Alpine version — /etc/alpine-release not found."
    fi

    if [ "$errors" -gt 0 ]; then
        echo "Aborting due to $errors error(s)."
        exit 1
    fi
}

write_log() {
    message="$1"
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

write_separator() {
    echo "============================================================" | tee -a "$LOG_FILE"
}

mkdir -p "$LOG_DIR"
check_requirements

write_separator
write_log "🏔️  Alpine Linux update started - $(date)"
write_log "Version: $(cat /etc/alpine-release 2>/dev/null || echo 'unknown')"
write_log "Kernel: $(uname -r)"
write_separator

# apk update & upgrade
write_log ""
write_log "📦 Updating apk packages..."
apk update 2>&1 | tee -a "$LOG_FILE"

write_log ""
write_log "⬆️  Upgrading packages..."
apk upgrade 2>&1 | tee -a "$LOG_FILE"
write_log "✅ apk update complete."

# Cache cleanup
write_log ""
write_log "🧹 Cleaning apk cache..."
apk cache clean 2>&1 | tee -a "$LOG_FILE"
write_log "✅ Cache cleaned."

# Kernel update note
write_log ""
CURRENT_KERNEL=$(uname -r)
write_log "📋 Running kernel: $CURRENT_KERNEL"
write_log "ℹ️  If kernel was updated, reboot to apply: reboot"

write_log ""
write_separator
write_log "✅ All done! Log saved to $LOG_FILE"
write_separator
echo ""
printf "Press ENTER to close..."
read -r
