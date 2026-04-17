#!/bin/bash
# =============================================================
# update-arch — Arch Linux / Manjaro / EndeavourOS maintenance
# Requires: Any current Arch-based distribution
# Covers: pacman, AUR (yay/paru), flatpak, firmware, orphan cleanup
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

LOG_DIR="$HOME/logs/arch"
LOG_FILE="$LOG_DIR/arch-update.log"

check_requirements() {
    local errors=0

    # Must have pacman
    if ! command -v pacman &>/dev/null; then
        echo "ERROR: pacman not found. This script requires an Arch-based system."
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

DISTRO=$(grep "^NAME" /etc/os-release 2>/dev/null | cut -d'=' -f2 | tr -d '"' || echo "Arch-based")

write_separator
write_log "🎯 $DISTRO update started - $(date)"
write_log "Kernel: $(uname -r)"
write_separator

# pacman
write_log ""
write_log "📦 Updating pacman packages..."
sudo pacman -Syu --noconfirm 2>&1 | tee -a "$LOG_FILE"
write_log "✅ pacman update complete."

# AUR helper
write_log ""
write_log "📦 Checking AUR packages..."
if command -v paru &>/dev/null; then
    write_log "⬆️  Updating AUR packages with paru..."
    paru -Syu --noconfirm 2>&1 | tee -a "$LOG_FILE"
    write_log "✅ AUR update complete (paru)."
elif command -v yay &>/dev/null; then
    write_log "⬆️  Updating AUR packages with yay..."
    yay -Syu --noconfirm 2>&1 | tee -a "$LOG_FILE"
    write_log "✅ AUR update complete (yay)."
else
    write_log "ℹ️  No AUR helper found (paru/yay). Skipping AUR updates."
    write_log "    Install paru: git clone https://aur.archlinux.org/paru.git && cd paru && makepkg -si"
fi

# Orphan cleanup
write_log ""
write_log "🧹 Checking for orphaned packages..."
ORPHANS=$(pacman -Qtdq 2>/dev/null)
if [ -n "$ORPHANS" ]; then
    write_log "⚠️  Orphaned packages found:"
    echo "$ORPHANS" | tee -a "$LOG_FILE"
    read -r -p "Remove orphaned packages? (y/N): " REPLY
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        sudo pacman -Rns $ORPHANS --noconfirm 2>&1 | tee -a "$LOG_FILE"
        write_log "✅ Orphans removed."
    else
        write_log "⏭️  Skipping orphan removal."
    fi
else
    write_log "✅ No orphaned packages found."
fi

# Flatpak (optional)
write_log ""
if command -v flatpak &>/dev/null; then
    write_log "📦 Updating flatpak packages..."
    flatpak update -y 2>&1 | tee -a "$LOG_FILE"
    write_log "✅ Flatpak update complete."
else
    write_log "ℹ️  flatpak not installed — skipping."
fi

# Firmware (optional)
write_log ""
if command -v fwupdmgr &>/dev/null; then
    write_log "🔧 Checking firmware updates..."
    fwupdmgr refresh 2>&1 | tee -a "$LOG_FILE"
    fwupdmgr get-updates 2>&1 | tee -a "$LOG_FILE"
else
    write_log "ℹ️  fwupd not installed — skipping firmware updates."
fi

# pacman cache cleanup
write_log ""
write_log "🧹 Cleaning pacman cache (keeping last 2 versions)..."
if command -v paccache &>/dev/null; then
    sudo paccache -r 2>&1 | tee -a "$LOG_FILE"
else
    write_log "ℹ️  paccache not found. Install pacman-contrib: sudo pacman -S pacman-contrib"
fi

write_log ""
write_separator
write_log "✅ All done! Log saved to $LOG_FILE"
write_separator
echo ""
echo "Press ENTER to close..."
read -r
