#!/bin/bash
# =============================================================
# update-linux — Linux maintenance and update automation script
# Supports: apt (Debian/Ubuntu), dnf (Fedora/RHEL), pacman (Arch)
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

LOG_DIR="$HOME/logs/linux"
LOG_FILE="$LOG_DIR/linux-update.log"

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

# Detect package manager
detect_pm() {
    if command -v apt &>/dev/null; then
        echo "apt"
    elif command -v dnf &>/dev/null; then
        echo "dnf"
    elif command -v pacman &>/dev/null; then
        echo "pacman"
    elif command -v zypper &>/dev/null; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

PM=$(detect_pm)

write_separator
write_log "🐧 Linux update started - $(date)"
write_log "📋 Detected package manager: $PM"
write_separator

# =============================================================
# Package updates
# =============================================================
write_log ""
write_log "📦 Updating packages..."

case "$PM" in
    apt)
        write_log "⬆️  Running apt update && upgrade..."
        sudo apt update 2>&1 | tee -a "$LOG_FILE"
        sudo apt upgrade -y 2>&1 | tee -a "$LOG_FILE"
        write_log "🧹 Cleaning up..."
        sudo apt autoremove -y 2>&1 | tee -a "$LOG_FILE"
        sudo apt autoclean 2>&1 | tee -a "$LOG_FILE"
        ;;
    dnf)
        write_log "⬆️  Running dnf upgrade..."
        sudo dnf upgrade -y 2>&1 | tee -a "$LOG_FILE"
        write_log "🧹 Cleaning up..."
        sudo dnf autoremove -y 2>&1 | tee -a "$LOG_FILE"
        sudo dnf clean all 2>&1 | tee -a "$LOG_FILE"
        ;;
    pacman)
        write_log "⬆️  Running pacman -Syu..."
        sudo pacman -Syu --noconfirm 2>&1 | tee -a "$LOG_FILE"
        write_log "🧹 Cleaning up orphans..."
        sudo pacman -Rns $(pacman -Qtdq) --noconfirm 2>/dev/null || write_log "No orphans to remove."
        ;;
    zypper)
        write_log "⬆️  Running zypper update..."
        sudo zypper update -y 2>&1 | tee -a "$LOG_FILE"
        ;;
    *)
        write_log "❌ Unknown package manager. Skipping package updates."
        ;;
esac

write_log "✅ Package update complete."

# =============================================================
# Snap (if installed)
# =============================================================
write_log ""
if command -v snap &>/dev/null; then
    write_log "📦 Updating snap packages..."
    sudo snap refresh 2>&1 | tee -a "$LOG_FILE"
    write_log "✅ Snap update complete."
fi

# =============================================================
# Flatpak (if installed)
# =============================================================
write_log ""
if command -v flatpak &>/dev/null; then
    write_log "📦 Updating flatpak packages..."
    flatpak update -y 2>&1 | tee -a "$LOG_FILE"
    write_log "✅ Flatpak update complete."
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
