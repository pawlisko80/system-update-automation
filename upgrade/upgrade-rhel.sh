#!/bin/bash
# =============================================================
# upgrade-rhel — RHEL/Fedora/Rocky/AlmaLinux major version upgrade
# Supports: Fedora N→N+1, RHEL/Rocky/Alma 8→9
# NOTE: CentOS 7 EOL — migrate to Rocky/AlmaLinux instead
# IMPORTANT: Read UPGRADE-GUIDE.md before running
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

LOG_DIR="$HOME/logs/rhel"
LOG_FILE="$LOG_DIR/rhel-upgrade-$(date +%Y%m%d).log"
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

preflight() {
    local errors=0
    write_log "🔍 Running pre-flight checks..."

    # Must have dnf
    if ! command -v dnf &>/dev/null; then
        write_log "ERROR: dnf not found."
        if command -v yum &>/dev/null; then
            write_log "       yum found — CentOS 7 is EOL and not supported."
            write_log "       Migrate to Rocky Linux or AlmaLinux instead."
        fi
        errors=$((errors + 1))
    fi

    # sudo check
    if [ "$EUID" -ne 0 ] && ! sudo -n true 2>/dev/null; then
        write_log "ERROR: sudo privileges required."
        errors=$((errors + 1))
    fi

    # Disk space (require 5GB)
    local free_gb=$(df / | awk 'NR==2 {print int($4/1024/1024)}')
    if [ "$free_gb" -lt 5 ]; then
        write_log "ERROR: Less than 5GB free. Found: ${free_gb}GB"
        errors=$((errors + 1))
    else
        write_log "✅ Disk space: ${free_gb}GB free"
    fi

    # Current version
    if [ -f /etc/os-release ]; then
        local distro=$(grep "^NAME=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
        local version=$(grep "^VERSION_ID=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
        write_log "✅ Current: $distro $version"
    fi

    if [ "$errors" -gt 0 ]; then
        write_log "❌ Pre-flight failed. Aborting."
        exit 1
    fi
    write_log "✅ Pre-flight checks passed."
}

backup() {
    write_log ""
    write_log "💾 Creating pre-upgrade backup..."
    local backup_dir="/root/pre-upgrade-backup-$(date +%Y%m%d)"
    mkdir -p "$backup_dir"
    rpm -qa > "$backup_dir/installed-packages.txt"
    write_log "✅ Package list saved to $backup_dir/installed-packages.txt"
    write_log "ℹ️  For full backup consider: tar -czf /root/etc-backup.tar.gz /etc"
}

upgrade_fedora() {
    local current=$(grep "^VERSION_ID=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
    local next=$((current + 1))

    write_log ""
    write_log "🎯 Fedora upgrade: $current → $next"

    # Install system-upgrade plugin
    write_log "📦 Installing dnf-plugin-system-upgrade..."
    sudo dnf install -y dnf-plugin-system-upgrade 2>&1 | tee -a "$LOG_FILE"

    write_log ""
    read -r -p "Download Fedora $next packages? (y/N): " REPLY
    if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
        write_log "⏭️  Upgrade cancelled."
        exit 0
    fi

    write_log "⬇️  Downloading Fedora $next..."
    sudo dnf system-upgrade download --releasever="$next" -y 2>&1 | tee -a "$LOG_FILE"

    if [ $? -ne 0 ]; then
        write_log "❌ Download failed. Check output above."
        write_log "ℹ️  Common fix: sudo dnf system-upgrade download --releasever=$next --allowerasing -y"
        exit 1
    fi

    write_log ""
    write_log "⚠️  System will reboot to complete upgrade."
    read -r -p "Reboot and upgrade now? (y/N): " REPLY
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        write_log "🔄 Rebooting to complete Fedora $next upgrade..."
        sudo dnf system-upgrade reboot
    else
        write_log "ℹ️  Run when ready: sudo dnf system-upgrade reboot"
    fi
}

upgrade_rhel() {
    local distro=$(grep "^NAME=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
    local current=$(grep "^VERSION_ID=" /etc/os-release | cut -d'=' -f2 | tr -d '"' | cut -d. -f1)
    local next=$((current + 1))

    write_log ""
    write_log "🎯 $distro upgrade: $current → $next"
    write_log ""
    write_log "⚠️  RHEL/Rocky/AlmaLinux major upgrades require:"
    write_log "   1. Valid subscription (RHEL) or repo access"
    write_log "   2. leapp upgrade tool"
    write_log ""

    # Check for leapp
    if ! command -v leapp &>/dev/null; then
        write_log "⬆️  Installing leapp..."
        sudo dnf install -y leapp-upgrade 2>&1 | tee -a "$LOG_FILE"
    fi

    if ! command -v leapp &>/dev/null; then
        write_log "ERROR: leapp not available. Cannot proceed with automated upgrade."
        write_log "ℹ️  Manual upgrade resources:"
        write_log "   Rocky: https://docs.rockylinux.org/guides/migrate2rocky/"
        write_log "   Alma:  https://wiki.almalinux.org/migration/"
        write_log "   RHEL:  https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux"
        exit 1
    fi

    write_log ""
    write_log "🔍 Running leapp pre-upgrade check..."
    sudo leapp preupgrade 2>&1 | tee -a "$LOG_FILE"

    write_log ""
    write_log "⚠️  Review the leapp report above before proceeding."
    read -r -p "Proceed with upgrade to $distro $next? (y/N): " REPLY
    if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
        write_log "⏭️  Upgrade cancelled."
        exit 0
    fi

    write_log "⬆️  Starting leapp upgrade..."
    sudo leapp upgrade 2>&1 | tee -a "$LOG_FILE"

    write_log ""
    write_log "⚠️  System will reboot to complete upgrade."
    read -r -p "Reboot now? (y/N): " REPLY
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        write_log "🔄 Rebooting..."
        sudo reboot
    else
        write_log "ℹ️  Run when ready: sudo reboot"
    fi
}

# =============================================================
# Main
# =============================================================
write_separator
write_log "🎩 RHEL/Fedora major version upgrade - $(date)"
write_separator

preflight
backup

DISTRO_ID=$(grep "^ID=" /etc/os-release | cut -d'=' -f2 | tr -d '"')

case "$DISTRO_ID" in
    fedora)
        upgrade_fedora
        ;;
    rhel|centos|rocky|almalinux)
        upgrade_rhel
        ;;
    *)
        write_log "⚠️  Unknown distro ID: $DISTRO_ID"
        write_log "    Attempting RHEL-style upgrade..."
        upgrade_rhel
        ;;
esac

write_log ""
write_separator
write_log "✅ All done! Log saved to $LOG_FILE"
write_separator
echo ""
echo "Press ENTER to close..."
read -r
