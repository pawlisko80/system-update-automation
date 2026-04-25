#!/bin/bash
# =============================================================
# check-health.sh — System health check script
# Covers: disk, memory, CPU, services, SMART, uptime
# Platforms: Linux, macOS, FreeBSD
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

# Configuration
DISK_WARN_PERCENT=80
DISK_CRIT_PERCENT=90
LOG_DIR="$HOME/Documents/logs/health"
LOG_FILE="$LOG_DIR/health-$(date +%Y%m%d-%H%M%S).log"
ISSUES=0

mkdir -p "$LOG_DIR"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

ok()   { echo -e "${GREEN}  ✅ $1${NC}" | tee -a "$LOG_FILE"; }
warn() { echo -e "${YELLOW}  ⚠️  $1${NC}" | tee -a "$LOG_FILE"; ISSUES=$((ISSUES+1)); }
crit() { echo -e "${RED}  ❌ $1${NC}" | tee -a "$LOG_FILE"; ISSUES=$((ISSUES+1)); }
info() { echo -e "${BLUE}  ℹ️  $1${NC}" | tee -a "$LOG_FILE"; }
section() { echo "" | tee -a "$LOG_FILE"; echo -e "${BLUE}━━━ $1 ━━━${NC}" | tee -a "$LOG_FILE"; }

OS=$(uname -s)

echo "============================================================" | tee -a "$LOG_FILE"
echo "  System Health Check — $(date)" | tee -a "$LOG_FILE"
echo "  Host: $(hostname) | OS: $OS $(uname -r)" | tee -a "$LOG_FILE"
echo "============================================================" | tee -a "$LOG_FILE"

# =============================================================
# Uptime
# =============================================================
section "Uptime"
uptime | tee -a "$LOG_FILE"

# =============================================================
# Disk Usage
# =============================================================
section "Disk Usage"
if [ "$OS" = "Darwin" ]; then
    df -H 2>/dev/null | grep -v "^Filesystem\|^map\|^devfs\|timemachine\|TimeMachine\|Wrapper\|localsnapshot" | while read -r line; do
        usage=$(echo "$line" | awk '{print $5}' | tr -d '%')
        mount=$(echo "$line" | awk '{print $9}')
        size=$(echo "$line" | awk '{print $2}')
        used=$(echo "$line" | awk '{print $3}')
        if [ -n "$usage" ] && [ "$usage" -ge "$DISK_CRIT_PERCENT" ] 2>/dev/null; then
            crit "CRITICAL: $mount — ${usage}% used ($used of $size)"
        elif [ -n "$usage" ] && [ "$usage" -ge "$DISK_WARN_PERCENT" ] 2>/dev/null; then
            warn "WARNING: $mount — ${usage}% used ($used of $size)"
        else
            ok "$mount — ${usage}% used ($used of $size)"
        fi
    done
else
    df -h | grep -v "^Filesystem\|^tmpfs\|^devtmpfs\|^udev" | tail -n +2 | while read -r line; do
        usage=$(echo "$line" | awk '{print $5}' | tr -d '%')
        mount=$(echo "$line" | awk '{print $6}')
        size=$(echo "$line" | awk '{print $2}')
        used=$(echo "$line" | awk '{print $3}')
        if [ -n "$usage" ] && [ "$usage" -ge "$DISK_CRIT_PERCENT" ] 2>/dev/null; then
            crit "CRITICAL: $mount — ${usage}% used ($used of $size)"
        elif [ -n "$usage" ] && [ "$usage" -ge "$DISK_WARN_PERCENT" ] 2>/dev/null; then
            warn "WARNING: $mount — ${usage}% used ($used of $size)"
        else
            ok "$mount — ${usage}% used ($used of $size)"
        fi
    done
fi

# =============================================================
# Memory
# =============================================================
section "Memory"
if [ "$OS" = "Darwin" ]; then
    total=$(sysctl -n hw.memsize | awk '{printf "%.1f GB", $1/1024/1024/1024}')
    pressure=$(memory_pressure 2>/dev/null | grep "System memory pressure" | awk '{print $NF}')
    ok "Total RAM: $total"
    if [ -n "$pressure" ]; then
        case "$pressure" in
            Normal) ok "Memory pressure: $pressure" ;;
            Warn*)  warn "Memory pressure: $pressure" ;;
            Critical|Urgent) crit "Memory pressure: $pressure" ;;
            *) info "Memory pressure: $pressure" ;;
        esac
    fi
elif [ "$OS" = "FreeBSD" ]; then
    vmstat -s | grep -E "pages free|pages active" | tee -a "$LOG_FILE"
else
    free -h | tee -a "$LOG_FILE"
    # Check if memory usage > 90%
    mem_used=$(free | awk 'NR==2{printf "%.0f", $3/$2*100}')
    if [ "$mem_used" -ge 90 ] 2>/dev/null; then
        crit "Memory usage: ${mem_used}%"
    elif [ "$mem_used" -ge 75 ] 2>/dev/null; then
        warn "Memory usage: ${mem_used}%"
    else
        ok "Memory usage: ${mem_used}%"
    fi
fi

# =============================================================
# CPU Load
# =============================================================
section "CPU Load"
if [ "$OS" = "Darwin" ]; then
    CPU_CORES=$(sysctl -n hw.ncpu)
    LOAD=$(sysctl -n vm.loadavg | awk '{print $2}')
else
    CPU_CORES=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 1)
    LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | tr -d ' ')
fi

LOAD_INT=$(echo "$LOAD" | cut -d. -f1)
if [ "$LOAD_INT" -ge "$CPU_CORES" ] 2>/dev/null; then
    warn "High load average: $LOAD (cores: $CPU_CORES)"
else
    ok "Load average: $LOAD (cores: $CPU_CORES)"
fi

# =============================================================
# Failed Services (Linux only)
# =============================================================
if [ "$OS" = "Linux" ]; then
    section "Systemd Services"
    if command -v systemctl &>/dev/null; then
        FAILED=$(systemctl --failed --no-legend 2>/dev/null | grep -c "failed" || echo 0)
        if [ "$FAILED" -gt 0 ]; then
            crit "$FAILED failed service(s):"
            systemctl --failed --no-legend 2>/dev/null | tee -a "$LOG_FILE"
        else
            ok "No failed services"
        fi
    else
        info "systemctl not available"
    fi
fi

# =============================================================
# SMART Disk Health
# =============================================================
section "Disk Health (SMART)"
if command -v smartctl &>/dev/null; then
    DISKS_CHECKED=0
    for disk in /dev/sd[a-z] /dev/nvme[0-9]n[0-9] /dev/disk[0-9]; do
        if [ -b "$disk" ] 2>/dev/null; then
            STATUS=$(smartctl -H "$disk" 2>/dev/null | grep "overall-health\|result:" | awk '{print $NF}')
            if [ -n "$STATUS" ]; then
                DISKS_CHECKED=$((DISKS_CHECKED+1))
                case "$STATUS" in
                    PASSED|OK) ok "$disk: $STATUS" ;;
                    *) crit "$disk: $STATUS" ;;
                esac
            fi
        fi
    done
    if [ "$DISKS_CHECKED" -eq 0 ]; then
        info "No disks found for SMART check (may need root)"
    fi
else
    info "smartctl not found — install smartmontools for disk health checks"
fi

# =============================================================
# Last Logins (Linux/macOS)
# =============================================================
section "Recent Logins"
last | head -5 | tee -a "$LOG_FILE"

# =============================================================
# Network
# =============================================================
section "Network"
if [ "$OS" = "Darwin" ]; then
    # Check default gateway reachable
    GW=$(route -n get default 2>/dev/null | grep gateway | awk '{print $2}')
    if [ -n "$GW" ]; then
        if ping -c 1 -W 2 "$GW" &>/dev/null; then
            ok "Gateway $GW reachable"
        else
            warn "Gateway $GW unreachable"
        fi
    fi
    # Internet check
    if ping -c 1 -W 3 8.8.8.8 &>/dev/null; then
        ok "Internet connectivity: OK"
    else
        crit "No internet connectivity"
    fi
else
    # Linux network check
    if ping -c 1 -W 3 8.8.8.8 &>/dev/null; then
        ok "Internet connectivity: OK"
    else
        crit "No internet connectivity"
    fi
fi

# =============================================================
# Summary
# =============================================================
echo "" | tee -a "$LOG_FILE"
echo "============================================================" | tee -a "$LOG_FILE"
if [ "$ISSUES" -eq 0 ]; then
    echo -e "${GREEN}  ✅ Health check passed — no issues found${NC}" | tee -a "$LOG_FILE"
elif [ "$ISSUES" -eq 1 ]; then
    echo -e "${YELLOW}  ⚠️  Health check complete — 1 issue found${NC}" | tee -a "$LOG_FILE"
else
    echo -e "${RED}  ❌ Health check complete — $ISSUES issues found${NC}" | tee -a "$LOG_FILE"
fi
echo "  Log saved to $LOG_FILE" | tee -a "$LOG_FILE"
echo "============================================================" | tee -a "$LOG_FILE"
echo ""
echo "Press ENTER to close..."
read -r
