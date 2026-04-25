#!/bin/bash
# =============================================================
# inventory.sh — System inventory report
# Generates a report of OS, hardware, installed packages
# Platforms: Linux, macOS, FreeBSD
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

REPORT_DIR="$HOME/logs/inventory"
REPORT_FILE="$REPORT_DIR/inventory-$(hostname)-$(date +%Y%m%d).txt"
mkdir -p "$REPORT_DIR"

OS=$(uname -s)

w() { echo "$1" | tee -a "$REPORT_FILE"; }
section() { w ""; w "=== $1 ==="; }

w "============================================================"
w "  System Inventory Report"
w "  Host: $(hostname)"
w "  Generated: $(date)"
w "  OS: $OS $(uname -r)"
w "============================================================"

# =============================================================
# Hardware
# =============================================================
section "Hardware"
if [ "$OS" = "Darwin" ]; then
    system_profiler SPHardwareDataType 2>/dev/null | grep -E "Model Name|Chip|Memory|Serial" | tee -a "$REPORT_FILE"
elif [ "$OS" = "Linux" ]; then
    if command -v dmidecode &>/dev/null; then
        sudo dmidecode -t system 2>/dev/null | grep -E "Manufacturer|Product|Serial|UUID" | tee -a "$REPORT_FILE"
    fi
    w "CPU: $(cat /proc/cpuinfo 2>/dev/null | grep "model name" | head -1 | cut -d: -f2 | xargs)"
    w "Cores: $(nproc 2>/dev/null || echo unknown)"
    w "RAM: $(free -h 2>/dev/null | awk '/^Mem:/{print $2}' || echo unknown)"
fi

# =============================================================
# OS Details
# =============================================================
section "OS Details"
if [ "$OS" = "Darwin" ]; then
    sw_vers | tee -a "$REPORT_FILE"
    w "Architecture: $(uname -m)"
elif [ -f /etc/os-release ]; then
    cat /etc/os-release | grep -E "^NAME|^VERSION" | tee -a "$REPORT_FILE"
fi
w "Kernel: $(uname -r)"
w "Uptime: $(uptime | sed 's/.*up //' | sed 's/,.*//')"

# =============================================================
# Disk
# =============================================================
section "Disk"
df -h 2>/dev/null | grep -v "^tmpfs\|^devtmpfs\|^udev\|^map\|^devfs\|timemachine\|TimeMachine\|Wrapper\|localsnapshot" | tee -a "$REPORT_FILE"

# =============================================================
# Network
# =============================================================
section "Network Interfaces"
if [ "$OS" = "Darwin" ]; then
    ifconfig | grep -E "^[a-z]|inet " | grep -v "127.0.0.1\|::1" | tee -a "$REPORT_FILE"
else
    ip addr 2>/dev/null | grep -E "^[0-9]|inet " | grep -v "127.0.0.1\|::1" | tee -a "$REPORT_FILE" || \
    ifconfig | grep -E "^[a-z]|inet " | grep -v "127.0.0.1\|::1" | tee -a "$REPORT_FILE"
fi

# =============================================================
# Installed Packages
# =============================================================
section "Package Manager Summary"
if [ "$OS" = "Darwin" ]; then
    if command -v brew &>/dev/null; then
        FORMULAE=$(brew list --formula 2>/dev/null | wc -l | tr -d ' ')
        CASKS=$(brew list --cask 2>/dev/null | wc -l | tr -d ' ')
        w "Homebrew formulae: $FORMULAE"
        w "Homebrew casks: $CASKS"
        w ""
        w "--- Casks (GUI apps) ---"
        brew list --cask 2>/dev/null | tee -a "$REPORT_FILE"
        w ""
        w "--- Formulae (CLI tools) ---"
        brew list --formula 2>/dev/null | tee -a "$REPORT_FILE"
    fi
    if command -v mas &>/dev/null; then
        w ""
        w "--- App Store apps ---"
        mas list 2>/dev/null | tee -a "$REPORT_FILE"
    fi
elif command -v apt &>/dev/null; then
    COUNT=$(dpkg -l 2>/dev/null | grep "^ii" | wc -l | tr -d ' ')
    w "apt packages installed: $COUNT"
    dpkg -l 2>/dev/null | grep "^ii" | awk '{print $2, $3}' | tee -a "$REPORT_FILE"
elif command -v dnf &>/dev/null; then
    COUNT=$(rpm -qa 2>/dev/null | wc -l | tr -d ' ')
    w "rpm packages installed: $COUNT"
    rpm -qa --qf "%{NAME} %{VERSION}\n" 2>/dev/null | sort | tee -a "$REPORT_FILE"
elif command -v pacman &>/dev/null; then
    COUNT=$(pacman -Q 2>/dev/null | wc -l | tr -d ' ')
    w "pacman packages installed: $COUNT"
    pacman -Q 2>/dev/null | tee -a "$REPORT_FILE"
elif command -v pkg &>/dev/null; then
    COUNT=$(pkg info 2>/dev/null | wc -l | tr -d ' ')
    w "pkg packages installed: $COUNT"
    pkg info 2>/dev/null | tee -a "$REPORT_FILE"
fi

# =============================================================
# Running Services (Linux)
# =============================================================
if [ "$OS" = "Linux" ] && command -v systemctl &>/dev/null; then
    section "Running Services"
    systemctl list-units --type=service --state=running --no-legend 2>/dev/null | \
        awk '{print $1}' | tee -a "$REPORT_FILE"
fi

# =============================================================
# Security
# =============================================================
section "Security Summary"
if [ "$OS" = "Linux" ]; then
    # Last logins
    w "Last 5 logins:"
    last | head -5 | tee -a "$REPORT_FILE"

    # Open ports
    w ""
    w "Listening ports:"
    if command -v ss &>/dev/null; then
        ss -tlnp 2>/dev/null | tee -a "$REPORT_FILE"
    elif command -v netstat &>/dev/null; then
        netstat -tlnp 2>/dev/null | tee -a "$REPORT_FILE"
    fi
elif [ "$OS" = "Darwin" ]; then
    w "Last 5 logins:"
    last | head -5 | tee -a "$REPORT_FILE"
fi

w ""
w "============================================================"
w "  Report saved to: $REPORT_FILE"
w "============================================================"

echo ""
echo "✅ Inventory complete! Report saved to:"
echo "   $REPORT_FILE"
echo ""
echo "Press ENTER to close..."
read -r
