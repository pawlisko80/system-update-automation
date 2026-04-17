#!/bin/bash
# =============================================================
# upgrade-debian — Debian/Ubuntu major version upgrade script
# Supports: Debian 10→11→12, Ubuntu 20.04→22.04→24.04
# IMPORTANT: Read UPGRADE-GUIDE.md before running
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

LOG_DIR="$HOME/logs/debian"
LOG_FILE="$LOG_DIR/debian-upgrade-$(date +%Y%m%d).log"
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

# =============================================================
# Pre-flight checks
# =============================================================
preflight() {
    local errors=0

    write_log "🔍 Running pre-flight checks..."

    # Must be Debian-based
    if ! command -v apt &>/dev/null; then
        write_log "ERROR: apt not found. Not a Debian-based system."
        errors=$((errors + 1))
    fi

    # Must be root/sudo
    if [ "$EUID" -ne 0 ] && ! sudo -n true 2>/dev/null; then
        write_log "ERROR: sudo privileges required."
        errors=$((errors + 1))
    fi

    # Disk space check (require 5GB free)
    local free_gb=$(df / | awk 'NR==2 {print int($4/1024/1024)}')
    if [ "$free_gb" -lt 5 ]; then
        write_log "ERROR: Less than 5GB free disk space. Found: ${free_gb}GB"
        write_log "       Free up space before upgrading."
        errors=$((errors + 1))
    else
        write_log "✅ Disk space: ${free_gb}GB free"
    fi

    # Current version
    if command -v lsb_release &>/dev/null; then
        local distro=$(lsb_release -si)
        local codename=$(lsb_release -sc)
        local version=$(lsb_release -sr)
        write_log "✅ Current: $distro $version ($codename)"
    fi

    # Check do-release-upgrade is available (Ubuntu)
    if command -v do-release-upgrade &>/dev/null; then
        write_log "✅ do-release-upgrade found"
    fi

    # All packages must be up to date first
    local upgradable=$(apt list --upgradable 2>/dev/null | grep -c "upgradable" || echo 0)
    if [ "$upgradable" -gt 0 ]; then
        write_log "⚠️  WARNING: $upgradable package(s) not up to date."
        write_log "   Run update-debian.sh first before upgrading."
    else
        write_log "✅ All packages up to date"
    fi

    if [ "$errors" -gt 0 ]; then
        write_log "❌ Pre-flight failed with $errors error(s). Aborting."
        exit 1
    fi

    write_log "✅ Pre-flight checks passed."
}

# =============================================================
# Backup
# =============================================================
backup() {
    write_log ""
    write_log "💾 Creating pre-upgrade backup..."

    local backup_dir="/root/pre-upgrade-backup-$(date +%Y%m%d)"
    mkdir -p "$backup_dir"

    # Backup sources.list
    cp -r /etc/apt/sources.list* "$backup_dir/" 2>/dev/null
    write_log "✅ apt sources backed up to $backup_dir"

    # List installed packages
    dpkg --get-selections > "$backup_dir/installed-packages.txt"
    write_log "✅ Package list saved to $backup_dir/installed-packages.txt"

    # Backup /etc
    write_log "ℹ️  For full system backup, consider snapshotting your VM or running:"
    write_log "   tar -czf /root/etc-backup.tar.gz /etc"
}

# =============================================================
# Debian upgrade
# =============================================================
upgrade_debian() {
    local current_codename=$(lsb_release -sc 2>/dev/null)

    # Determine next version
    case "$current_codename" in
        buster)   NEXT="bullseye"; NEXT_VER="11" ;;
        bullseye) NEXT="bookworm"; NEXT_VER="12" ;;
        bookworm) NEXT="trixie";   NEXT_VER="13" ;;
        *)
            write_log "⚠️  Unknown codename: $current_codename"
            write_log "    Manually set target in /etc/apt/sources.list"
            return 1
            ;;
    esac

    write_log ""
    write_log "🎯 Upgrade path: $current_codename → $NEXT (Debian $NEXT_VER)"
    write_log ""
    read -r -p "Proceed with upgrade to Debian $NEXT_VER ($NEXT)? (y/N): " REPLY
    if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
        write_log "⏭️  Upgrade cancelled."
        exit 0
    fi

    write_log "⬆️  Updating apt sources to $NEXT..."
    sudo sed -i "s/$current_codename/$NEXT/g" /etc/apt/sources.list
    sudo sed -i "s/$current_codename/$NEXT/g" /etc/apt/sources.list.d/*.list 2>/dev/null
    write_log "✅ Sources updated."

    write_log ""
    write_log "📦 Updating package list..."
    sudo apt update 2>&1 | tee -a "$LOG_FILE"

    write_log ""
    write_log "⬆️  Running minimal upgrade first..."
    sudo apt upgrade -y 2>&1 | tee -a "$LOG_FILE"

    write_log ""
    write_log "⬆️  Running full upgrade..."
    sudo apt full-upgrade -y 2>&1 | tee -a "$LOG_FILE"

    write_log ""
    write_log "🧹 Cleaning up..."
    sudo apt autoremove -y 2>&1 | tee -a "$LOG_FILE"
    sudo apt autoclean 2>&1 | tee -a "$LOG_FILE"

    write_log ""
    write_log "✅ Upgrade to Debian $NEXT_VER ($NEXT) complete!"
    write_log "⚠️  A reboot is required to complete the upgrade."
    read -r -p "Reboot now? (y/N): " REPLY
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        write_log "🔄 Rebooting..."
        sudo reboot
    else
        write_log "ℹ️  Remember to reboot: sudo reboot"
    fi
}

# =============================================================
# Ubuntu upgrade
# =============================================================
upgrade_ubuntu() {
    write_log ""
    write_log "🎯 Ubuntu upgrade via do-release-upgrade"
    write_log ""
    write_log "ℹ️  Ubuntu upgrade options:"
    write_log "   Normal:  do-release-upgrade (next LTS or standard)"
    write_log "   LTS only: do-release-upgrade -d (development)"
    write_log ""

    if ! command -v do-release-upgrade &>/dev/null; then
        write_log "ERROR: do-release-upgrade not found."
        write_log "Install with: sudo apt install ubuntu-release-upgrader-core"
        exit 1
    fi

    local current=$(lsb_release -sr)
    write_log "Current Ubuntu version: $current"
    write_log ""

    read -r -p "Run do-release-upgrade now? (y/N): " REPLY
    if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
        write_log "⏭️  Upgrade cancelled."
        exit 0
    fi

    write_log "⬆️  Starting Ubuntu release upgrade..."
    sudo do-release-upgrade 2>&1 | tee -a "$LOG_FILE"
}

# =============================================================
# Main
# =============================================================
write_separator
write_log "🐧 Debian/Ubuntu major version upgrade - $(date)"
write_separator

preflight
backup

DISTRO=$(lsb_release -si 2>/dev/null || echo "unknown")

case "$DISTRO" in
    Ubuntu)
        upgrade_ubuntu
        ;;
    Debian|*Mint*)
        upgrade_debian
        ;;
    *)
        write_log "⚠️  Unknown distro: $DISTRO"
        write_log "    Attempting Debian-style upgrade..."
        upgrade_debian
        ;;
esac

write_log ""
write_separator
write_log "✅ All done! Log saved to $LOG_FILE"
write_separator
echo ""
echo "Press ENTER to close..."
read -r
