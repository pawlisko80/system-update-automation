#!/bin/bash
# =============================================================
# update-raspi — Raspberry Pi OS maintenance and update script
# Covers: apt, rpi-update (firmware), rpi-eeprom (bootloader)
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

LOG_DIR="$HOME/logs/raspios"
LOG_FILE="$LOG_DIR/raspi-update.log"

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
write_log "🍓 Raspberry Pi update started - $(date)"
write_separator

# =============================================================
# System packages
# =============================================================
write_log ""
write_log "📦 Updating system packages..."
sudo apt update 2>&1 | tee -a "$LOG_FILE"
sudo apt upgrade -y 2>&1 | tee -a "$LOG_FILE"
sudo apt full-upgrade -y 2>&1 | tee -a "$LOG_FILE"
write_log "✅ System packages updated."

# =============================================================
# Cleanup
# =============================================================
write_log ""
write_log "🧹 Cleaning up..."
sudo apt autoremove -y 2>&1 | tee -a "$LOG_FILE"
sudo apt autoclean 2>&1 | tee -a "$LOG_FILE"
write_log "✅ Cleanup complete."

# =============================================================
# Raspberry Pi firmware (rpi-update)
# =============================================================
write_log ""
write_log "🔧 Checking Raspberry Pi firmware (rpi-update)..."

if command -v rpi-update &>/dev/null; then
    read -r -p "Update Pi firmware via rpi-update? This may cause instability. (y/N): " REPLY
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        write_log "⬆️  Running rpi-update..."
        sudo rpi-update 2>&1 | tee -a "$LOG_FILE"
        write_log "✅ Firmware update complete. Reboot required."
    else
        write_log "⏭️  Skipping rpi-update."
    fi
else
    write_log "⚠️  rpi-update not found. Install with: sudo apt install rpi-update"
fi

# =============================================================
# EEPROM bootloader update (Pi 4/5 only)
# =============================================================
write_log ""
write_log "🔧 Checking EEPROM bootloader..."

if command -v rpi-eeprom-update &>/dev/null; then
    EEPROM_STATUS=$(sudo rpi-eeprom-update 2>&1)
    echo "$EEPROM_STATUS" | tee -a "$LOG_FILE"

    if echo "$EEPROM_STATUS" | grep -q "UPDATE AVAILABLE"; then
        write_log "⚠️  EEPROM update available!"
        read -r -p "Install EEPROM update? (y/N): " REPLY
        if [[ "$REPLY" =~ ^[Yy]$ ]]; then
            write_log "⬆️  Installing EEPROM update..."
            sudo rpi-eeprom-update -a 2>&1 | tee -a "$LOG_FILE"
            write_log "✅ EEPROM update staged. Reboot required to apply."
        else
            write_log "⏭️  Skipping EEPROM update."
        fi
    else
        write_log "✅ EEPROM bootloader is up to date."
    fi
else
    write_log "ℹ️  rpi-eeprom-update not found. Skipping (normal on Pi 2/3)."
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
