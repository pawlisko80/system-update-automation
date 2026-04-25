#!/bin/bash
# =============================================================
# update-chromeos.sh - ChromeOS / Crostini maintenance script
# Requires: ChromeOS with Linux (Crostini) enabled
# Covers: apt (Debian), flatpak, Android apps via ADB (optional)
# Run inside the Linux terminal on ChromeOS
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

LOG_DIR="$HOME/logs/chromeos"
LOG_FILE="$LOG_DIR/chromeos-update.log"

check_requirements() {
    local errors=0

    # Must be running inside Crostini (Linux on ChromeOS)
    if [ ! -f /etc/debian_version ] && ! grep -q "penguin\|cros\|chromeos" /etc/hostname 2>/dev/null; then
        # Additional check via environment
        if [ -z "$SOMMELIER_VERSION" ] && ! systemd-detect-virt 2>/dev/null | grep -q "lxc\|container"; then
            echo "WARNING: Could not confirm Crostini environment - proceeding anyway."
        fi
    fi

    # Must have apt (Crostini is Debian-based)
    if ! command -v apt &>/dev/null; then
        echo "ERROR: apt not found. ChromeOS Linux (Crostini) uses Debian - apt is required."
        errors=$((errors + 1))
    fi

    # sudo check
    if [ "$EUID" -ne 0 ] && ! sudo -n true 2>/dev/null; then
        echo "ERROR: This script requires sudo privileges."
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

DEBIAN_VER=$(cat /etc/debian_version 2>/dev/null || echo "unknown")
HOSTNAME=$(hostname)

write_separator
write_log "ChromeOS Linux (Crostini) update started - $(date)"
write_log "Container: $HOSTNAME | Debian: $DEBIAN_VER"
write_separator

# =============================================================
# apt packages (Debian base)
# =============================================================
write_log ""
write_log "Updating apt packages..."
sudo apt update 2>&1 | tee -a "$LOG_FILE"

write_log ""
write_log "Upgrading packages..."
sudo apt upgrade -y 2>&1 | tee -a "$LOG_FILE"

write_log ""
write_log "Running full-upgrade..."
sudo apt full-upgrade -y 2>&1 | tee -a "$LOG_FILE"

write_log ""
write_log "Cleaning up..."
sudo apt autoremove -y 2>&1 | tee -a "$LOG_FILE"
sudo apt autoclean 2>&1 | tee -a "$LOG_FILE"
write_log "apt update complete."

# =============================================================
# Flatpak (optional - common on ChromeOS Linux)
# =============================================================
write_log ""
if command -v flatpak &>/dev/null; then
    write_log "Updating flatpak packages..."
    flatpak update -y 2>&1 | tee -a "$LOG_FILE"
    write_log "Flatpak update complete."
else
    write_log "flatpak not installed - skipping."
    write_log "Install with: sudo apt install flatpak"
fi

# =============================================================
# Snap (optional)
# =============================================================
write_log ""
if command -v snap &>/dev/null; then
    write_log "Updating snap packages..."
    sudo snap refresh 2>&1 | tee -a "$LOG_FILE"
    write_log "Snap update complete."
else
    write_log "snap not installed - skipping."
fi

# =============================================================
# Android apps via ADB (optional)
# =============================================================
write_log ""
write_log "Checking ADB (Android app updates)..."
if command -v adb &>/dev/null; then
    # Check if Android container is running
    ADB_DEVICES=$(adb devices 2>/dev/null | grep -v "^List\|^$" | wc -l)
    if [ "$ADB_DEVICES" -gt 0 ]; then
        write_log "Android container detected via ADB."
        write_log "Android app updates must be done via Google Play Store."
        write_log "  Open Play Store -> tap your profile -> Manage apps and devices -> Update all"
    else
        write_log "ADB available but no Android container connected."
    fi
else
    write_log "ADB not installed - skipping Android app check."
    write_log "Install with: sudo apt install adb"
fi

# =============================================================
# ChromeOS system update reminder
# =============================================================
write_log ""
write_log "========================================"
write_log "Manual update reminders:"
write_log "========================================"
write_log ">> ChromeOS system: Settings -> About ChromeOS -> Check for updates"
write_log ">> Android apps: Google Play Store -> Profile -> Manage apps -> Update all"
write_log ">> Chrome browser: chrome://settings/help"

# =============================================================
# Reboot check
# =============================================================
write_log ""
if [ -f /var/run/reboot-required ]; then
    write_log "System reboot required!"
    read -r -p "Restart Linux container now? (y/N): " REPLY
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        write_log "Restarting Linux container..."
        write_log "Note: This only restarts the Linux container, not ChromeOS itself."
        sudo reboot
    else
        write_log "Skipping restart."
        write_log "Restart manually: right-click Linux terminal -> Shut down Linux"
    fi
else
    write_log "No reboot required."
fi

write_log ""
write_separator
write_log "All done! Log saved to $LOG_FILE"
write_separator
echo ""
echo "Press ENTER to close..."
read -r
