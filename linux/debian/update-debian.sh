#!/bin/bash
# =============================================================
# update-debian — Debian/Ubuntu/Mint maintenance script
# Requires: Debian 10+, Ubuntu 20.04+, Linux Mint 20+
# Covers: apt, snap, flatpak, firmware, security updates
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

LOG_DIR="$HOME/logs/debian"
LOG_FILE="$LOG_DIR/debian-update.log"

# =============================================================
# Version checks
# =============================================================
check_requirements() {
    local errors=0

    # Must be Debian-based
    if ! command -v apt &>/dev/null; then
        echo "ERROR: apt not found. This script requires a Debian-based system."
        errors=$((errors + 1))
    fi

    # Check Debian/Ubuntu version
    if command -v lsb_release &>/dev/null; then
        local distro=$(lsb_release -si)
        local version=$(lsb_release -sr | cut -d. -f1)
        case "$distro" in
            Debian)
                if [ "$version" -lt 10 ] 2>/dev/null; then
                    echo "ERROR: Debian 10 (Buster) or later required. Found: $distro $version"
                    errors=$((errors + 1))
                fi
                ;;
            Ubuntu)
                if [ "$version" -lt 20 ] 2>/dev/null; then
                    echo "ERROR: Ubuntu 20.04 or later required. Found: $distro $version"
                    errors=$((errors + 1))
                fi
                ;;
            *Mint*)
                if [ "$version" -lt 20 ] 2>/dev/null; then
                    echo "ERROR: Linux Mint 20 or later required. Found: $distro $version"
                    errors=$((errors + 1))
                fi
                ;;
        esac
    else
        echo "WARNING: lsb_release not found — cannot verify distro version."
        echo "         Install with: apt install lsb-release"
    fi

    # Must run as root or with sudo
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

# =============================================================
# Setup
# =============================================================
mkdir -p "$LOG_DIR"
check_requirements

DISTRO=$(lsb_release -si 2>/dev/null || grep "^NAME" /etc/os-release 2>/dev/null | cut -d'=' -f2 | tr -d '"' || echo "Debian-based")
VERSION=$(lsb_release -sr 2>/dev/null || grep "^VERSION_ID" /etc/os-release 2>/dev/null | cut -d'=' -f2 | tr -d '"' || echo "unknown")

write_separator
write_log "🐧 $DISTRO $VERSION update started - $(date)"
write_log "Kernel: $(uname -r)"
write_separator

# =============================================================
# apt
# =============================================================
write_log ""
write_log "📦 Updating apt packages..."
sudo apt update 2>&1 | tee -a "$LOG_FILE"

write_log ""
write_log "⬆️  Upgrading packages..."
sudo apt upgrade -y 2>&1 | tee -a "$LOG_FILE"

write_log ""
write_log "⬆️  Running full-upgrade..."
sudo apt full-upgrade -y 2>&1 | tee -a "$LOG_FILE"

write_log ""
write_log "🧹 Cleaning up..."
sudo apt autoremove -y 2>&1 | tee -a "$LOG_FILE"
sudo apt autoclean 2>&1 | tee -a "$LOG_FILE"
write_log "✅ apt update complete."

# =============================================================
# Snap (optional)
# =============================================================
write_log ""
if command -v snap &>/dev/null; then
    write_log "📦 Updating snap packages..."
    sudo snap refresh 2>&1 | tee -a "$LOG_FILE"
    write_log "✅ Snap update complete."
else
    write_log "ℹ️  snap not installed — skipping."
fi

# =============================================================
# Flatpak (optional)
# =============================================================
write_log ""
if command -v flatpak &>/dev/null; then
    write_log "📦 Updating flatpak packages..."
    flatpak update -y 2>&1 | tee -a "$LOG_FILE"
    write_log "✅ Flatpak update complete."
else
    write_log "ℹ️  flatpak not installed — skipping."
fi

# =============================================================
# Firmware (fwupd) — Ubuntu 20.04+ / Debian 10+
# =============================================================
write_log ""
if command -v fwupdmgr &>/dev/null; then
    write_log "🔧 Checking firmware updates..."
    fwupdmgr refresh 2>&1 | tee -a "$LOG_FILE"
    FWUPD_OUT=$(fwupdmgr get-updates 2>&1)
    echo "$FWUPD_OUT" | tee -a "$LOG_FILE"
    if echo "$FWUPD_OUT" | grep -q "No upgrades"; then
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
    write_log "ℹ️  fwupd not installed — skipping firmware updates."
    write_log "    Install with: sudo apt install fwupd"
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
