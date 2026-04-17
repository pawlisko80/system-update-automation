#!/bin/bash
# =============================================================
# common/utils.sh — Shared utility functions
# Source this file from any platform script:
#   source "$(dirname "$0")/../common/utils.sh"
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log file — override in calling script before sourcing
LOG_FILE="${LOG_FILE:-/tmp/system-update.log}"

# =============================================================
# Logging
# =============================================================
write_log() {
    local message="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local line="[$timestamp] $message"
    echo -e "$line" | tee -a "$LOG_FILE"
}

write_separator() {
    local line
    line=$(printf '=%.0s' {1..60})
    echo "$line" | tee -a "$LOG_FILE"
}

write_info()    { write_log "ℹ️  $1"; }
write_success() { write_log "✅ $1"; }
write_warning() { write_log "⚠️  $1"; }
write_error()   { write_log "❌ $1"; }
write_step()    { write_log "⬆️  $1"; }

# =============================================================
# System detection
# =============================================================
detect_os() {
    case "$(uname -s)" in
        Darwin)  echo "mac" ;;
        FreeBSD) echo "freebsd" ;;
        Linux)
            if grep -q "Raspberry Pi\|raspbian\|Raspberry" /proc/cpuinfo /etc/os-release 2>/dev/null; then
                echo "raspios"
            else
                echo "linux"
            fi
            ;;
        *) echo "unknown" ;;
    esac
}

detect_linux_pm() {
    if command -v apt &>/dev/null;    then echo "apt"
    elif command -v dnf &>/dev/null;  then echo "dnf"
    elif command -v pacman &>/dev/null; then echo "pacman"
    elif command -v zypper &>/dev/null; then echo "zypper"
    else echo "unknown"
    fi
}

# =============================================================
# Prompts
# =============================================================
prompt_yes_no() {
    local question="$1"
    local default="${2:-n}"
    printf "%s (y/N): " "$question"
    read -r REPLY
    [[ "$REPLY" =~ ^[Yy]$ ]]
}

# =============================================================
# Docker helpers
# =============================================================
docker_update_all() {
    if command -v docker &>/dev/null; then
        write_step "Pulling latest images for running containers..."
        docker ps --format "{{.Image}}" | sort -u | while read -r image; do
            write_log "   Pulling: $image"
            docker pull "$image" 2>&1 | tee -a "$LOG_FILE"
        done
        write_step "Removing unused Docker images..."
        docker image prune -f 2>&1 | tee -a "$LOG_FILE"
        write_success "Docker update complete."
    else
        write_info "Docker not found. Skipping."
    fi
}

# =============================================================
# Disk health
# =============================================================
check_smart_health() {
    if command -v smartctl &>/dev/null; then
        write_log "💾 Disk health summary..."
        for disk in /dev/sd[a-z] /dev/nvme[0-9]n[0-9]; do
            if [ -b "$disk" ]; then
                STATUS=$(smartctl -H "$disk" 2>/dev/null | grep "overall-health\|result:" | awk '{print $NF}')
                write_log "   $disk: ${STATUS:-unknown}"
            fi
        done
    else
        write_info "smartctl not found. Skipping disk health check."
    fi
}

# =============================================================
# Reboot check
# =============================================================
check_reboot_required() {
    if [ -f /var/run/reboot-required ]; then
        write_warning "System reboot is required!"
        if prompt_yes_no "Reboot now?"; then
            write_log "🔄 Rebooting..."
            reboot
        else
            write_info "Skipping reboot. Remember to reboot during a maintenance window."
        fi
    else
        write_success "No reboot required."
    fi
}
