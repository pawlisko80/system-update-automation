#!/bin/sh
# =============================================================
# upgrade-freebsd — FreeBSD major version upgrade script
# Supports: FreeBSD 12→13→14
# IMPORTANT: Read UPGRADE-GUIDE.md before running
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

LOG_DIR="$HOME/logs/freebsd"
LOG_FILE="$LOG_DIR/freebsd-upgrade-$(date +%Y%m%d).log"
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
    write_log "🔍 Running pre-flight checks..."

    if [ "$(uname -s)" != "FreeBSD" ]; then
        write_log "ERROR: Not a FreeBSD system."
        errors=$((errors + 1))
    fi

    if [ "$(id -u)" -ne 0 ]; then
        write_log "ERROR: Must run as root."
        errors=$((errors + 1))
    fi

    # Disk space (require 3GB)
    free_gb=$(df / | awk 'NR==2 {print int($4/1024/1024)}')
    if [ "$free_gb" -lt 3 ]; then
        write_log "ERROR: Less than 3GB free. Found: ${free_gb}GB"
        errors=$((errors + 1))
    else
        write_log "OK  Disk space: ${free_gb}GB free"
    fi

    CURRENT_VER=$(uname -r | cut -d. -f1)
    CURRENT_FULL=$(uname -r)
    write_log "OK  Current: FreeBSD $CURRENT_FULL"

    # Must be on RELEASE not CURRENT/STABLE
    if echo "$CURRENT_FULL" | grep -q "CURRENT\|STABLE"; then
        write_log "WARNING: Running $CURRENT_FULL — freebsd-update only supports RELEASE."
        write_log "         For CURRENT/STABLE, build from source."
    fi

    if [ "$errors" -gt 0 ]; then
        write_log "ERROR: Pre-flight failed. Aborting."
        exit 1
    fi
    write_log "OK  Pre-flight checks passed."
}

backup() {
    write_log ""
    write_log "Backing up installed packages list..."
    pkg info > "/root/pre-upgrade-packages-$(date +%Y%m%d).txt" 2>/dev/null
    write_log "OK  Package list saved."
    write_log "INFO: For full backup consider snapshot or:"
    write_log "      tar -czf /root/etc-backup.tar.gz /etc /usr/local/etc"
}

# =============================================================
# Main
# =============================================================
write_separator
write_log "FreeBSD major version upgrade - $(date)"
write_separator

preflight
backup

CURRENT_VER=$(uname -r | cut -d. -f1)
NEXT_VER=$((CURRENT_VER + 1))

write_log ""
write_log "Target: FreeBSD $CURRENT_VER → $NEXT_VER"
write_log ""
write_log "FreeBSD upgrade is a multi-step process:"
write_log "  Step 1: freebsd-update upgrade -r ${NEXT_VER}.0-RELEASE"
write_log "  Step 2: freebsd-update install  (first run)"
write_log "  Step 3: reboot"
write_log "  Step 4: freebsd-update install  (second run — kernel modules)"
write_log "  Step 5: pkg upgrade             (upgrade all packages)"
write_log "  Step 6: reboot"
write_log ""
write_log "NOTE: FreeBSD $NEXT_VER may not be released yet."
write_log "      Check https://www.freebsd.org/releases/ for available versions."
write_log ""

printf "Proceed with upgrade to FreeBSD %s? (y/N): " "$NEXT_VER"
read -r REPLY
if [ "$REPLY" != "y" ] && [ "$REPLY" != "Y" ]; then
    write_log "Upgrade cancelled."
    exit 0
fi

# Step 1 — Fetch upgrade
write_log ""
write_log "Step 1: Fetching FreeBSD ${NEXT_VER}.0-RELEASE..."
freebsd-update upgrade -r "${NEXT_VER}.0-RELEASE" 2>&1 | tee -a "$LOG_FILE"

if [ $? -ne 0 ]; then
    write_log "ERROR: Fetch failed. Check output above."
    write_log "Common causes:"
    write_log "  - Target release not yet available"
    write_log "  - Network connectivity issue"
    write_log "  - Custom kernel (only GENERIC supported)"
    exit 1
fi

# Step 2 — First install
write_log ""
write_log "Step 2: Installing (first pass — base system)..."
freebsd-update install 2>&1 | tee -a "$LOG_FILE"

write_log ""
write_log "Step 3: Reboot required to boot into new kernel."
printf "Reboot now? (y/N): "
read -r REPLY
if [ "$REPLY" = "y" ] || [ "$REPLY" = "Y" ]; then
    write_log "Rebooting..."
    write_log ""
    write_log "AFTER REBOOT — complete the upgrade:"
    write_log "  freebsd-update install   (second pass)"
    write_log "  pkg upgrade              (upgrade packages)"
    write_log "  reboot                   (final reboot)"
    reboot
else
    write_log ""
    write_log "NEXT STEPS after reboot:"
    write_log "  freebsd-update install"
    write_log "  pkg upgrade"
    write_log "  reboot"
fi

write_log ""
write_separator
write_log "Log saved to $LOG_FILE"
write_separator
