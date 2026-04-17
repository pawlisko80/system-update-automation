#!/bin/sh
# =============================================================
# update-esxi — VMware ESXi maintenance script
# Covers: esxcli updates, VIB patches, patch baseline check
# Run directly on ESXi host via SSH
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

LOG_DIR="/scratch/logs/esxi"
LOG_FILE="$LOG_DIR/esxi-update.log"

mkdir -p "$LOG_DIR"

write_log() {
    message="$1"
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

write_separator() {
    echo "============================================================" | tee -a "$LOG_FILE"
}

write_separator
write_log "🟦 ESXi update started - $(date)"
write_log "📋 Version: $(vmware -v 2>/dev/null || echo 'unknown')"
write_log "📋 Hostname: $(hostname)"
write_separator

# =============================================================
# Current patch level
# =============================================================
write_log ""
write_log "📋 Current patch level..."
esxcli system version get 2>&1 | tee -a "$LOG_FILE"

# =============================================================
# Installed VIBs
# =============================================================
write_log ""
write_log "📦 Installed VIBs..."
esxcli software vib list 2>&1 | tee -a "$LOG_FILE"

# =============================================================
# Online depot update (requires internet access from ESXi)
# =============================================================
write_log ""
write_log "🔧 Checking for updates from VMware depot..."
write_log "ℹ️  Online update requires ESXi to have internet access."

printf "Check VMware online depot for updates? (y/N): "
read -r REPLY
if [ "$REPLY" = "y" ] || [ "$REPLY" = "Y" ]; then
    write_log "⬆️  Checking VMware depot..."
    esxcli network firewall ruleset set -e true -r httpClient 2>&1 | tee -a "$LOG_FILE"

    UPDATE_CHECK=$(esxcli software sources profile list -d https://hostupdate.vmware.com/software/VUM/PRODUCTION/main/vmw-depot-index.xml 2>&1)
    echo "$UPDATE_CHECK" | tee -a "$LOG_FILE"

    esxcli network firewall ruleset set -e false -r httpClient 2>&1 | tee -a "$LOG_FILE"
else
    write_log "⏭️  Skipping online depot check."
    write_log "ℹ️  For offline updates, use VMware vSphere Update Manager or:"
    write_log "    esxcli software profile update -d /path/to/depot.zip -p ESXi-x.x.x-xxxxxx-standard"
fi

# =============================================================
# VM status
# =============================================================
write_log ""
write_log "🖥️  VM inventory..."

if command -v vim-cmd >/dev/null 2>&1; then
    write_log "📋 Registered VMs:"
    vim-cmd vmsvc/getallvms 2>&1 | tee -a "$LOG_FILE"

    write_log ""
    write_log "📋 Running VMs:"
    vim-cmd vmsvc/getallvms 2>/dev/null | awk 'NR>1 {print $1}' | while read -r vmid; do
        POWER=$(vim-cmd vmsvc/power.getstate "$vmid" 2>/dev/null | tail -1)
        NAME=$(vim-cmd vmsvc/get.summary "$vmid" 2>/dev/null | grep "name = " | head -1 | awk -F'"' '{print $2}')
        write_log "   VM $vmid ($NAME): $POWER"
    done
fi

# =============================================================
# Datastore status
# =============================================================
write_log ""
write_log "💾 Datastore status..."
esxcli storage filesystem list 2>&1 | tee -a "$LOG_FILE"

# =============================================================
# Network adapters
# =============================================================
write_log ""
write_log "🌐 Network adapters..."
esxcli network nic list 2>&1 | tee -a "$LOG_FILE"

# =============================================================
# Reboot check
# =============================================================
write_log ""
write_log "ℹ️  ESXi updates typically require a reboot."
write_log "    Schedule maintenance window and reboot with: reboot"
write_log "    Or use vCenter/vSphere for rolling updates in clustered environments."

# =============================================================
# Done
# =============================================================
write_log ""
write_separator
write_log "✅ All done! Log saved to $LOG_FILE"
write_separator
echo ""
printf "Press ENTER to close..."
read -r
