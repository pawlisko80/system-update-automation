#!/bin/sh
# =============================================================
# update-freebsd — FreeBSD maintenance and update script
# Requires: FreeBSD 12.0+
# NOTE: portsnap deprecated in FreeBSD 14+ (use git instead)
# Covers: freebsd-update (base), pkg (packages), ports (optional)
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

LOG_DIR="$HOME/logs/freebsd"
LOG_FILE="$LOG_DIR/freebsd-update.log"

check_requirements() {
    local errors=0

    # Must be FreeBSD
    if [ "$(uname -s)" != "FreeBSD" ]; then
        echo "ERROR: This script requires FreeBSD."
        errors=$((errors + 1))
    fi

    # Version check (require 12+)
    FBSD_VER=$(uname -r | cut -d. -f1)
    if [ "$FBSD_VER" -lt 12 ] 2>/dev/null; then
        echo "ERROR: FreeBSD 12.0 or later required. Found: $(uname -r)"
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
    message="$1"
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

write_separator() {
    echo "============================================================" | tee -a "$LOG_FILE"
}

mkdir -p "$LOG_DIR"
check_requirements

FBSD_VER=$(uname -r | cut -d. -f1)

write_separator
write_log "😈 FreeBSD update started - $(date)"
write_log "Version: $(uname -r) | Running as: $(whoami)"
write_separator

# Base system update
write_log ""
write_log "🔧 Checking FreeBSD base system updates..."
write_log "⬆️  Fetching base system updates..."
freebsd-update fetch 2>&1 | tee -a "$LOG_FILE"

UPDATE_COUNT=$(freebsd-update updatesready 2>&1)
if echo "$UPDATE_COUNT" | grep -q "No updates"; then
    write_log "✅ Base system is up to date."
else
    write_log "⚠️  Base system updates available!"
    printf "Install base system updates? (y/N): "
    read -r REPLY
    if [ "$REPLY" = "y" ] || [ "$REPLY" = "Y" ]; then
        write_log "⬆️  Installing base system updates..."
        freebsd-update install 2>&1 | tee -a "$LOG_FILE"
        write_log "✅ Base system updated. Reboot may be required."
    else
        write_log "⏭️  Skipping base system updates."
    fi
fi

# pkg packages
write_log ""
write_log "📦 Updating pkg packages..."
if command -v pkg >/dev/null 2>&1; then
    pkg update 2>&1 | tee -a "$LOG_FILE"
    pkg upgrade -y 2>&1 | tee -a "$LOG_FILE"
    write_log "🧹 Cleaning up..."
    pkg autoremove -y 2>&1 | tee -a "$LOG_FILE"
    pkg clean -y 2>&1 | tee -a "$LOG_FILE"
    write_log "✅ pkg update complete."
else
    write_log "❌ pkg not found. Skipping."
fi

# Ports tree update
# NOTE: portsnap deprecated in FreeBSD 14+, use git instead
write_log ""
write_log "🌳 Checking ports tree..."
if [ -d /usr/ports ]; then
    if [ "$FBSD_VER" -ge 14 ]; then
        write_log "ℹ️  FreeBSD 14+: portsnap is deprecated."
        if command -v git >/dev/null 2>&1 && [ -d /usr/ports/.git ]; then
            write_log "⬆️  Updating ports tree via git..."
            git -C /usr/ports pull 2>&1 | tee -a "$LOG_FILE"
            write_log "✅ Ports tree updated via git."
        else
            write_log "ℹ️  To use ports on FreeBSD 14+, clone with git:"
            write_log "    git clone https://git.FreeBSD.org/ports.git /usr/ports"
        fi
    else
        if command -v portsnap >/dev/null 2>&1; then
            write_log "⬆️  Updating ports tree via portsnap..."
            portsnap fetch update 2>&1 | tee -a "$LOG_FILE"
            write_log "✅ Ports tree updated."
        else
            write_log "ℹ️  portsnap not found. Skipping."
        fi
    fi
else
    write_log "ℹ️  Ports tree not installed. Skipping."
fi

write_log ""
write_separator
write_log "✅ All done! Log saved to $LOG_FILE"
write_separator
echo ""
printf "Press ENTER to close..."
read -r
