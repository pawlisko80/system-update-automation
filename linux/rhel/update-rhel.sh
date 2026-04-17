#!/bin/bash
# =============================================================
# update-rhel — RHEL/Fedora/CentOS/Rocky/AlmaLinux maintenance
# Requires: RHEL 8+, Fedora 33+, Rocky/Alma 8+
# NOTE: CentOS 7 and earlier use yum not dnf — not supported
# Covers: dnf, flatpak, firmware
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

LOG_DIR="$HOME/logs/rhel"
LOG_FILE="$LOG_DIR/rhel-update.log"

check_requirements() {
    local errors=0

    # Must have dnf (not yum-only systems like CentOS 7)
    if ! command -v dnf &>/dev/null; then
        if command -v yum &>/dev/null; then
            echo "ERROR: Only 'yum' found. This script requires 'dnf'."
            echo "       CentOS 7 and earlier are not supported."
            echo "       Supported: RHEL 8+, Fedora 33+, Rocky 8+, AlmaLinux 8+"
        else
            echo "ERROR: Neither dnf nor yum found. Is this a RHEL-based system?"
        fi
        errors=$((errors + 1))
    fi

    # Version check
    if [ -f /etc/os-release ]; then
        local distro=$(grep "^ID=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
        local version=$(grep "^VERSION_ID=" /etc/os-release | cut -d'=' -f2 | tr -d '"' | cut -d. -f1)
        case "$distro" in
            rhel|centos|rocky|almalinux)
                if [ "$version" -lt 8 ] 2>/dev/null; then
                    echo "ERROR: $distro version 8 or later required. Found: $version"
                    errors=$((errors + 1))
                fi
                ;;
            fedora)
                if [ "$version" -lt 33 ] 2>/dev/null; then
                    echo "ERROR: Fedora 33 or later required. Found: $version"
                    errors=$((errors + 1))
                fi
                ;;
        esac
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

DISTRO=$(grep "^NAME" /etc/os-release 2>/dev/null | cut -d'=' -f2 | tr -d '"' || echo "RHEL-based")
VERSION=$(grep "^VERSION_ID" /etc/os-release 2>/dev/null | cut -d'=' -f2 | tr -d '"' || echo "unknown")

write_separator
write_log "🎩 $DISTRO $VERSION update started - $(date)"
write_log "Kernel: $(uname -r)"
write_separator

# Subscription check (RHEL only)
write_log ""
if command -v subscription-manager &>/dev/null; then
    write_log "🔑 Subscription status..."
    subscription-manager status 2>&1 | tee -a "$LOG_FILE"
fi

# dnf update
write_log ""
write_log "📦 Updating dnf packages..."
sudo dnf check-update 2>&1 | tee -a "$LOG_FILE"
write_log ""
write_log "⬆️  Upgrading packages..."
sudo dnf upgrade -y 2>&1 | tee -a "$LOG_FILE"
write_log "✅ dnf update complete."

# Security summary
write_log ""
write_log "🔒 Security updates summary..."
sudo dnf updateinfo summary 2>&1 | tee -a "$LOG_FILE"

# Cleanup
write_log ""
write_log "🧹 Removing unused packages..."
sudo dnf autoremove -y 2>&1 | tee -a "$LOG_FILE"
sudo dnf clean all 2>&1 | tee -a "$LOG_FILE"
write_log "✅ Cleanup complete."

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

# Reboot check
write_log ""
if command -v needs-restarting &>/dev/null && needs-restarting -r &>/dev/null; then
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
