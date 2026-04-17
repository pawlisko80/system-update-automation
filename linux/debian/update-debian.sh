#!/bin/bash
# =============================================================
# update-debian — Debian/Ubuntu/Mint maintenance script
# Covers: apt, snap, flatpak, firmware, security updates
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

LOG_DIR="$HOME/logs/debian"
LOG_FILE="$LOG_DIR/debian-update.log"

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

# Detect distro
DISTRO=$(lsb_release -si 2>/dev/null || grep "^NAME" /etc/os-release 2>/dev/null | cut -d'=' -f2 | tr -d '"' || echo "Debian-based")
VERSION=$(lsb_release -sr 2>/dev/null || grep "^VERSION_ID" /etc/os-release 2>/dev/null | cut -d'=' -f2 | tr -d '"' || echo "unknown")

write_separator
write_log "🐧 $DISTRO $VERSION update started - $(date)"
write_log "📋 Kernel: $(uname -r)"
write_separator

# =============================================================
# apt update & upgrade
# =============================================================
write_log ""
write_log "📦 Updating apt packages..."
sudo apt update 2>&1 | tee -a "$LOG_FILE"

write_log ""
write_log "⬆️  Upgrading packages..."
sudo apt upgrade -y 2>&1 | tee -a "$LOG_FILE"

write_log ""
write_log "⬆️  Running full-upgrade (handles dependency changes)..."
sudo apt full-upgrade -y 2>&1 | tee -a "$LOG_FILE"

write_log ""
write_log "🧹 Cleaning up..."
sudo apt autoremove -y 2>&1 | tee -a "$LOG_FILE"
sudo apt autoclean 2>&1 | tee -a "$LOG_FILE"
write_log "✅ apt update complete."

# =============================================================
# Security updates only check
# =============================================================
write_log ""
write_log "🔒 Security updates status..."
if command -v unattended-upgrade &>/dev/null; then
    sudo unattended-upgrade --dry-run 2>&1 | tee -a "$LOG_FILE"
fi

# =============================================================
# Snap
# =============================================================
write_log ""
if command -v snap &>/dev/null; then
    write_log "📦 Updating snap packages..."
    sudo snap refresh 2>&1 | tee -a "$LOG_FILE"
    write_log "✅ Snap update complete."
fi

# =============================================================
# Flatpak
# =============================================================
write_log ""
if command -v flatpak &>/dev/null; then
    write_log "📦 Updating flatpak packages..."
    flatpak update -y 2>&1 | tee -a "$LOG_FILE"
    write_log "✅ Flatpak update complete."
fi

# =============================================================
# pip (Python packages)
# =============================================================
write_log ""
if command -v pip3 &>/dev/null; then
    write_log "🐍 Checking outdated pip packages..."
    pip3 list --outdated 2>/dev/null | tee -a "$LOG_FILE"
    write_log "ℹ️  Update individual pip packages with: pip3 install --upgrade <package>"
fi

# =============================================================
# Firmware updates
# =============================================================
write_log ""
write_log "🔧 Checking firmware updates..."
if command -v fwupdmgr &>/dev/null; then
    fwupdmgr refresh 2>&1 | tee -a "$LOG_FILE"
    fwupdmgr get-updates 2>&1 | tee -a "$LOG_FILE"

    UPDATES=$(fwupdmgr get-updates 2>/dev/null)
    if echo "$UPDATES" | grep -q "No upgrades"; then
        write_log "✅ Firmware is up to date."
    else
        read -r -p "Install firmware updates? (y/N): " REPLY
        if [[ "$REPLY" =~ ^[Yy]$ ]]; then
            write_log "⬆️  Installing firmware updates..."
            sudo fwupdmgr update 2>&1 | tee -a "$LOG_FILE"
            write_log "✅ Firmware updates installed."
        else
            write_log "⏭️  Skipping firmware updates."
        fi
    fi
else
    write_log "ℹ️  fwupdmgr not found. Install with: sudo apt install fwupd"
fi

# =============================================================
# Reboot check
# =============================================================
write_log ""
if [ -f /var/run/reboot-required ]; then
    write_log "⚠️  System reboot is required!"
    read -r -p "Reboot now? (y/N): " REPLY
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        write_log "🔄 Rebooting..."
        sudo reboot
    else
        write_log "⏭️  Skipping reboot. Remember to reboot when convenient."
    fi
else
    write_log "✅ No reboot required."
fi

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
