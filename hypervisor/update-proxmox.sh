#!/bin/bash
# =============================================================
# update-proxmox — Proxmox VE maintenance and update script
# Requires: Proxmox VE 7.0+
# NOTE: pveupgrade syntax differs between v6 and v7+
# Covers: apt, pveupgrade, LXC templates, VM/container status
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

LOG_DIR="/root/logs/proxmox"
LOG_FILE="$LOG_DIR/proxmox-update.log"

check_requirements() {
    local errors=0

    # Must be Proxmox
    if ! command -v pveversion &>/dev/null; then
        echo "ERROR: pveversion not found. Is this a Proxmox VE host?"
        errors=$((errors + 1))
    fi

    # Version check (require 7+)
    if command -v pveversion &>/dev/null; then
        local pve_ver=$(pveversion | grep -oP 'pve-manager/\K[0-9]+' | head -1)
        if [ -n "$pve_ver" ] && [ "$pve_ver" -lt 7 ] 2>/dev/null; then
            echo "ERROR: Proxmox VE 7.0 or later required. Found: $(pveversion)"
            echo "       For PVE 6.x, use apt upgrade manually."
            errors=$((errors + 1))
        fi
    fi

    # Must run as root
    if [ "$EUID" -ne 0 ]; then
        echo "ERROR: This script must be run as root."
        errors=$((errors + 1))
    fi

    # apt required
    if ! command -v apt &>/dev/null; then
        echo "ERROR: apt not found."
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

write_separator
write_log "🖥️  Proxmox VE update started - $(date)"
write_log "Version: $(pveversion 2>/dev/null || echo 'unknown')"
write_log "Hostname: $(hostname)"
write_separator

# apt update
write_log ""
write_log "📦 Updating Proxmox packages..."
apt update 2>&1 | tee -a "$LOG_FILE"
apt upgrade -y 2>&1 | tee -a "$LOG_FILE"
apt autoremove -y 2>&1 | tee -a "$LOG_FILE"
apt autoclean 2>&1 | tee -a "$LOG_FILE"
write_log "✅ Package update complete."

# pveupgrade (PVE 7+)
write_log ""
write_log "🔧 Checking Proxmox VE updates..."
if command -v pveupgrade &>/dev/null; then
    pveupgrade --color 0 2>&1 | tee -a "$LOG_FILE"
else
    write_log "ℹ️  pveupgrade not available on this version."
fi

# LXC templates
write_log ""
write_log "📦 Updating LXC container templates..."
if command -v pveam &>/dev/null; then
    pveam update 2>&1 | tee -a "$LOG_FILE"
    write_log "✅ Template list updated."
else
    write_log "ℹ️  pveam not available — skipping template update."
fi

# VM status
write_log ""
write_log "🖥️  Running VMs:"
if command -v qm &>/dev/null; then
    qm list 2>&1 | tee -a "$LOG_FILE"
else
    write_log "ℹ️  qm not available."
fi

write_log ""
write_log "📦 Running LXC containers:"
if command -v pct &>/dev/null; then
    pct list 2>&1 | tee -a "$LOG_FILE"
else
    write_log "ℹ️  pct not available."
fi

# Storage status
write_log ""
write_log "💾 Storage status..."
if command -v pvesm &>/dev/null; then
    pvesm status 2>&1 | tee -a "$LOG_FILE"
fi

# Disk health
write_log ""
write_log "💾 Disk health summary..."
if command -v smartctl &>/dev/null; then
    for disk in /dev/sd[a-z] /dev/nvme[0-9]n[0-9]; do
        if [ -b "$disk" ]; then
            STATUS=$(smartctl -H "$disk" 2>/dev/null | grep "overall-health\|result:" | awk '{print $NF}')
            write_log "   $disk: ${STATUS:-unknown}"
        fi
    done
else
    write_log "ℹ️  smartctl not found. Install with: apt install smartmontools"
fi

# Reboot check
write_log ""
if [ -f /var/run/reboot-required ]; then
    write_log "⚠️  System reboot is required!"
    printf "Reboot now? This will affect all running VMs/containers. (y/N): "
    read -r REPLY
    if [ "$REPLY" = "y" ] || [ "$REPLY" = "Y" ]; then
        write_log "🔄 Rebooting..."
        reboot
    else
        write_log "⏭️  Skipping reboot. Remember to reboot during a maintenance window."
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
