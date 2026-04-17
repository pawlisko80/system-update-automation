#!/bin/sh
# =============================================================
# update-freebsd — FreeBSD maintenance and update script
# Covers: freebsd-update (base), pkg (packages), ports (optional)
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

LOG_DIR="$HOME/logs/freebsd"
LOG_FILE="$LOG_DIR/freebsd-update.log"

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
write_log "😈 FreeBSD update started - $(date)"
write_log "📋 Running as: $(whoami) on $(hostname)"
write_separator

# =============================================================
# Base system update (freebsd-update)
# =============================================================
write_log ""
write_log "🔧 Checking FreeBSD base system updates..."

if [ "$(id -u)" -ne 0 ]; then
    write_log "⚠️  freebsd-update requires root. Run as root or with sudo."
else
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
fi

# =============================================================
# pkg packages
# =============================================================
write_log ""
write_log "📦 Updating pkg packages..."

if command -v pkg >/dev/null 2>&1; then
    write_log "⬆️  Running pkg upgrade..."
    pkg update 2>&1 | tee -a "$LOG_FILE"
    pkg upgrade -y 2>&1 | tee -a "$LOG_FILE"
    write_log "🧹 Cleaning up..."
    pkg autoremove -y 2>&1 | tee -a "$LOG_FILE"
    pkg clean -y 2>&1 | tee -a "$LOG_FILE"
    write_log "✅ pkg update complete."
else
    write_log "❌ pkg not found. Skipping."
fi

# =============================================================
# Ports tree update (optional)
# =============================================================
write_log ""
write_log "🌳 Checking ports tree..."

if [ -d /usr/ports ]; then
    if command -v portsnap >/dev/null 2>&1; then
        write_log "⬆️  Updating ports tree via portsnap..."
        portsnap fetch update 2>&1 | tee -a "$LOG_FILE"
        write_log "✅ Ports tree updated."
    elif command -v git >/dev/null 2>&1 && [ -d /usr/ports/.git ]; then
        write_log "⬆️  Updating ports tree via git..."
        git -C /usr/ports pull 2>&1 | tee -a "$LOG_FILE"
        write_log "✅ Ports tree updated."
    else
        write_log "ℹ️  No ports update method found. Skipping."
    fi
else
    write_log "ℹ️  Ports tree not installed. Skipping."
fi

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
