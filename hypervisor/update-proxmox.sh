#!/bin/bash
# =============================================================
# update-proxmox — Proxmox VE maintenance and update script
# Covers: apt, pveam templates, LXC containers, VM agents
# Run directly on Proxmox host via SSH
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

LOG_DIR="/root/logs/proxmox"
LOG_FILE="$LOG_DIR/proxmox-update.log"

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

write_separator
write_log "🖥️  Proxmox VE update started - $(date)"
write_log "📋 Version: $(pveversion 2>/dev/null || echo 'unknown')"
write_log "📋 Hostname: $(hostname)"
write_separator

# =============================================================
# apt update & upgrade
# =============================================================
write_log ""
write_log "📦 Updating Proxmox packages..."

apt update 2>&1 | tee -a "$LOG_FILE"
apt upgrade -y 2>&1 | tee -a "$LOG_FILE"
apt autoremove -y 2>&1 | tee -a "$LOG_FILE"
apt autoclean 2>&1 | tee -a "$LOG_FILE"
write_log "✅ Package update complete."

# =============================================================
# Proxmox VE specific update
# =============================================================
write_log ""
write_log "🔧 Checking Proxmox VE updates..."

if command -v pveupdate >/dev/null 2>&1; then
    pveupdate 2>&1 | tee -a "$LOG_FILE"
fi

if command -v pveupgrade >/dev/null 2>&1; then
    write_log "⬆️  Running pveupgrade..."
    pveupgrade --color 0 2>&1 | tee -a "$LOG_FILE"
fi

# =============================================================
# LXC container templates
# =============================================================
write_log ""
write_log "📦 Updating LXC container templates..."

if command -v pveam >/dev/null 2>&1; then
    write_log "⬆️  Updating template list..."
    pveam update 2>&1 | tee -a "$LOG_FILE"
    write_log "📋 Available updated templates:"
    pveam available --section system 2>/dev/null | head -10 | tee -a "$LOG_FILE"
    write_log "✅ Template list updated."
fi

# =============================================================
# Running VMs and containers status
# =============================================================
write_log ""
write_log "🖥️  Running VMs:"

if command -v qm >/dev/null 2>&1; then
    qm list 2>&1 | tee -a "$LOG_FILE"
fi

write_log ""
write_log "📦 Running LXC containers:"

if command -v pct >/dev/null 2>&1; then
    pct list 2>&1 | tee -a "$LOG_FILE"
fi

# =============================================================
# Update guest agents in running VMs (informational)
# =============================================================
write_log ""
write_log "ℹ️  To update QEMU guest agents inside VMs, SSH into each VM and run:"
write_log "    Debian/Ubuntu: sudo apt upgrade qemu-guest-agent -y"
write_log "    RHEL/Fedora:   sudo dnf upgrade qemu-guest-agent -y"
write_log "    Windows:       Use virtio-win installer from https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/"

# =============================================================
# Storage status
# =============================================================
write_log ""
write_log "💾 Storage status..."

if command -v pvesm >/dev/null 2>&1; then
    pvesm status 2>&1 | tee -a "$LOG_FILE"
fi

# =============================================================
# Cluster status (if clustered)
# =============================================================
write_log ""
write_log "🔗 Cluster status..."

if command -v pvecm >/dev/null 2>&1; then
    CLUSTER_STATUS=$(pvecm status 2>&1)
    if echo "$CLUSTER_STATUS" | grep -q "Cluster information"; then
        echo "$CLUSTER_STATUS" | tee -a "$LOG_FILE"
    else
        write_log "ℹ️  Not running in cluster mode."
    fi
fi

# =============================================================
# Disk health
# =============================================================
write_log ""
write_log "💾 Disk health summary..."

if command -v smartctl >/dev/null 2>&1; then
    for disk in /dev/sd[a-z] /dev/nvme[0-9]n[0-9]; do
        if [ -b "$disk" ]; then
            STATUS=$(smartctl -H "$disk" 2>/dev/null | grep "overall-health\|result:" | awk '{print $NF}')
            write_log "   $disk: ${STATUS:-unknown}"
        fi
    done
else
    write_log "ℹ️  smartctl not found. Install with: apt install smartmontools"
fi

# =============================================================
# Reboot check
# =============================================================
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
