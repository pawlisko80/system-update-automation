#!/bin/bash
# =============================================================
# update-raspi — Raspberry Pi OS maintenance and update script
# Requires: Raspberry Pi OS Buster (10)+ / Bookworm (12)+
# NOTE: rpi-eeprom only supported on Pi 4 and Pi 5
# Covers: apt, rpi-update (firmware), rpi-eeprom (bootloader)
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

LOG_DIR="$HOME/logs/raspios"
LOG_FILE="$LOG_DIR/raspi-update.log"

check_requirements() {
    local errors=0

    # Must be Raspberry Pi
    if ! grep -q "Raspberry Pi\|raspbian" /proc/cpuinfo /etc/os-release 2>/dev/null; then
        echo "ERROR: This script requires a Raspberry Pi running Raspberry Pi OS."
        errors=$((errors + 1))
    fi

    # Must have apt
    if ! command -v apt &>/dev/null; then
        echo "ERROR: apt not found."
        errors=$((errors + 1))
    fi

    # Version check (require Buster/10+)
    if command -v lsb_release &>/dev/null; then
        local version=$(lsb_release -sr | cut -d. -f1)
        if [ "$version" -lt 10 ] 2>/dev/null; then
            echo "ERROR: Raspberry Pi OS Buster (10) or later required. Found: $version"
            errors=$((errors + 1))
        fi
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

# Detect Pi model for eeprom compatibility
detect_pi_model() {
    if [ -f /proc/device-tree/model ]; then
        cat /proc/device-tree/model
    else
        echo "unknown"
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

PI_MODEL=$(detect_pi_model)

write_separator
write_log "🍓 Raspberry Pi update started - $(date)"
write_log "Model: $PI_MODEL"
write_log "OS: $(lsb_release -sd 2>/dev/null || echo 'Raspberry Pi OS')"
write_separator

# System packages
write_log ""
write_log "📦 Updating system packages..."
sudo apt update 2>&1 | tee -a "$LOG_FILE"
sudo apt upgrade -y 2>&1 | tee -a "$LOG_FILE"
sudo apt full-upgrade -y 2>&1 | tee -a "$LOG_FILE"
write_log "✅ System packages updated."

# Cleanup
write_log ""
write_log "🧹 Cleaning up..."
sudo apt autoremove -y 2>&1 | tee -a "$LOG_FILE"
sudo apt autoclean 2>&1 | tee -a "$LOG_FILE"
write_log "✅ Cleanup complete."

# rpi-update (firmware)
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
    write_log "⚠️  rpi-update not found."
    write_log "    Install with: sudo apt install rpi-update"
fi

# EEPROM bootloader (Pi 4 and Pi 5 only)
write_log ""
write_log "🔧 Checking EEPROM bootloader..."

if echo "$PI_MODEL" | grep -qE "Raspberry Pi [45]"; then
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
        write_log "⚠️  rpi-eeprom-update not found."
        write_log "    Install with: sudo apt install rpi-eeprom"
    fi
else
    write_log "ℹ️  EEPROM update only supported on Pi 4 and Pi 5. Skipping."
    write_log "    Detected model: $PI_MODEL"
fi

write_log ""
write_separator
write_log "✅ All done! Log saved to $LOG_FILE"
write_separator
echo ""
echo "Press ENTER to close..."
read -r
