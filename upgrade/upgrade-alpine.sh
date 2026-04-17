#!/bin/sh
# =============================================================
# upgrade-alpine — Alpine Linux major version upgrade script
# Supports: Alpine 3.x → 3.x+1
# IMPORTANT: Read UPGRADE-GUIDE.md before running
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

LOG_DIR="$HOME/logs/alpine"
LOG_FILE="$LOG_DIR/alpine-upgrade-$(date +%Y%m%d).log"
mkdir -p "$LOG_DIR"

write_log() {
    message="$1"
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

write_separator() {
    echo "============================================================" | tee -a "$LOG_FILE"
}

preflight() {
    errors=0
    write_log "Checking requirements..."

    if ! command -v apk >/dev/null 2>&1; then
        write_log "ERROR: apk not found. Not Alpine Linux."
        errors=$((errors + 1))
    fi

    if [ ! -f /etc/alpine-release ]; then
        write_log "ERROR: /etc/alpine-release not found."
        errors=$((errors + 1))
    fi

    # Disk space (require 500MB — Alpine is tiny)
    free_mb=$(df / | awk 'NR==2 {print int($4/1024)}')
    if [ "$free_mb" -lt 500 ]; then
        write_log "ERROR: Less than 500MB free. Found: ${free_mb}MB"
        errors=$((errors + 1))
    else
        write_log "OK  Disk space: ${free_mb}MB free"
    fi

    CURRENT_VER=$(cat /etc/alpine-release)
    write_log "OK  Current: Alpine $CURRENT_VER"

    # Check if running edge
    if grep -q "edge" /etc/apk/repositories 2>/dev/null; then
        write_log "INFO: Running Alpine Edge — already on rolling release."
        write_log "      Run: apk update && apk upgrade"
        exit 0
    fi

    if [ "$errors" -gt 0 ]; then
        write_log "ERROR: Pre-flight failed. Aborting."
        exit 1
    fi
    write_log "OK  Pre-flight passed."
}

# =============================================================
# Main
# =============================================================
write_separator
write_log "Alpine Linux major version upgrade - $(date)"
write_separator

preflight

CURRENT_FULL=$(cat /etc/alpine-release)
CURRENT_MINOR=$(echo "$CURRENT_FULL" | cut -d. -f1-2)
MAJOR=$(echo "$CURRENT_FULL" | cut -d. -f1)
MINOR=$(echo "$CURRENT_FULL" | cut -d. -f2)
NEXT_MINOR="$MAJOR.$((MINOR + 1))"

write_log ""
write_log "Upgrade path: Alpine $CURRENT_MINOR → $NEXT_MINOR"
write_log ""
write_log "NOTE: Check https://www.alpinelinux.org/releases/ to confirm"
write_log "      $NEXT_MINOR is available before proceeding."
write_log ""

printf "Proceed with upgrade to Alpine %s? (y/N): " "$NEXT_MINOR"
read -r REPLY
if [ "$REPLY" != "y" ] && [ "$REPLY" != "Y" ]; then
    write_log "Upgrade cancelled."
    exit 0
fi

# Backup current repos
write_log ""
write_log "Backing up current repositories..."
cp /etc/apk/repositories "/etc/apk/repositories.bak-$(date +%Y%m%d)"
write_log "OK  Repos backed up."

# Update repositories to new version
write_log ""
write_log "Updating /etc/apk/repositories to v$NEXT_MINOR..."
sed -i "s/v$CURRENT_MINOR/v$NEXT_MINOR/g" /etc/apk/repositories
write_log "Updated repos:"
cat /etc/apk/repositories | tee -a "$LOG_FILE"

# Update package list
write_log ""
write_log "Updating package list..."
apk update 2>&1 | tee -a "$LOG_FILE"

if [ $? -ne 0 ]; then
    write_log "ERROR: apk update failed."
    write_log "Restoring previous repositories..."
    cp "/etc/apk/repositories.bak-$(date +%Y%m%d)" /etc/apk/repositories
    write_log "Repositories restored. Please check if Alpine $NEXT_MINOR is available."
    exit 1
fi

# Upgrade all packages
write_log ""
write_log "Upgrading all packages to $NEXT_MINOR..."
apk upgrade --available 2>&1 | tee -a "$LOG_FILE"

write_log ""
write_log "Upgrade complete!"
write_log "Verify with: cat /etc/alpine-release"
write_log ""

printf "Reboot now? (y/N): "
read -r REPLY
if [ "$REPLY" = "y" ] || [ "$REPLY" = "Y" ]; then
    write_log "Rebooting..."
    reboot
else
    write_log "Remember to reboot: reboot"
fi

write_log ""
write_separator
write_log "Log saved to $LOG_FILE"
write_separator
