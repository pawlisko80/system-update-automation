#!/bin/bash
# =============================================================
# update-linux — Generic Linux maintenance script
# Auto-detects: apt (Debian/Ubuntu), dnf (Fedora/RHEL),
#               pacman (Arch), zypper (openSUSE)
# NOTE: For distro-specific scripts with better version checks,
#       use update-debian.sh, update-rhel.sh, update-arch.sh
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

LOG_DIR="$HOME/logs/linux"
LOG_FILE="$LOG_DIR/linux-update.log"

check_requirements() {
    local errors=0

    # Must be Linux
    if [ "$(uname -s)" != "Linux" ]; then
        echo "ERROR: This script requires Linux."
        errors=$((errors + 1))
    fi

    # Must have at least one supported package manager
    if ! command -v apt &>/dev/null && \
       ! command -v dnf &>/dev/null && \
       ! command -v pacman &>/dev/null && \
       ! command -v zypper &>/dev/null; then
        echo "ERROR: No supported package manager found."
        echo "       Supported: apt, dnf, pacman, zypper"
        echo "       For other package managers use the distro-specific script."
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

detect_pm() {
    if command -v apt &>/dev/null; then echo "apt"
    elif command -v dnf &>/dev/null; then echo "dnf"
    elif command -v pacman &>/dev/null; then echo "pacman"
    elif command -v zypper &>/dev/null; then echo "zypper"
    else echo "unknown"
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

PM=$(detect_pm)

write_separator
write_log "🐧 Linux update started - $(date)"
write_log "Distro: $(grep "^NAME" /etc/os-release 2>/dev/null | cut -d'=' -f2 | tr -d '"' || echo 'unknown')"
write_log "Package manager: $PM"
write_log "Kernel: $(uname -r)"
write_separator

write_log ""
write_log "📦 Updating packages via $PM..."

case "$PM" in
    apt)
        sudo apt update 2>&1 | tee -a "$LOG_FILE"
        sudo apt upgrade -y 2>&1 | tee -a "$LOG_FILE"
        write_log "🧹 Cleaning up..."
        sudo apt autoremove -y 2>&1 | tee -a "$LOG_FILE"
        sudo apt autoclean 2>&1 | tee -a "$LOG_FILE"
        ;;
    dnf)
        sudo dnf upgrade -y 2>&1 | tee -a "$LOG_FILE"
        write_log "🧹 Cleaning up..."
        sudo dnf autoremove -y 2>&1 | tee -a "$LOG_FILE"
        sudo dnf clean all 2>&1 | tee -a "$LOG_FILE"
        ;;
    pacman)
        sudo pacman -Syu --noconfirm 2>&1 | tee -a "$LOG_FILE"
        write_log "🧹 Cleaning orphans..."
        ORPHANS=$(pacman -Qtdq 2>/dev/null)
        if [ -n "$ORPHANS" ]; then
            sudo pacman -Rns $ORPHANS --noconfirm 2>&1 | tee -a "$LOG_FILE"
        fi
        ;;
    zypper)
        sudo zypper update -y 2>&1 | tee -a "$LOG_FILE"
        ;;
esac

write_log "✅ Package update complete."

# Snap (optional)
write_log ""
if command -v snap &>/dev/null; then
    write_log "📦 Updating snap packages..."
    sudo snap refresh 2>&1 | tee -a "$LOG_FILE"
    write_log "✅ Snap update complete."
fi

# Flatpak (optional)
write_log ""
if command -v flatpak &>/dev/null; then
    write_log "📦 Updating flatpak packages..."
    flatpak update -y 2>&1 | tee -a "$LOG_FILE"
    write_log "✅ Flatpak update complete."
fi

# Reboot check
write_log ""
if [ -f /var/run/reboot-required ]; then
    write_log "⚠️  System reboot is required!"
    read -r -p "Reboot now? (y/N): " REPLY
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        write_log "🔄 Rebooting..."
        sudo reboot
    else
        write_log "⏭️  Skipping reboot."
    fi
else
    write_log "✅ No reboot required."
fi

write_log ""
write_separator
write_log "✅ All done! Log saved to $LOG_FILE"
write_separator
echo ""
echo "Press ENTER to close..."
read -r
