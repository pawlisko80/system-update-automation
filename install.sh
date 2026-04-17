#!/bin/bash
# =============================================================
# install.sh — Universal installer for system-update-automation
# Detects OS and sets up the correct update script automatically
# Repo: https://github.com/pawlisko80/system-update-automation
# Usage: curl -fsSL https://raw.githubusercontent.com/pawlisko80/system-update-automation/main/install.sh | bash
# =============================================================

REPO="https://github.com/pawlisko80/system-update-automation.git"
INSTALL_DIR="$HOME/scripts"

echo "============================================================"
echo "  system-update-automation installer"
echo "============================================================"
echo ""

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Darwin)
            echo "mac"
            ;;
        Linux)
            if grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null || \
               grep -q "raspbian" /etc/os-release 2>/dev/null || \
               grep -q "Raspberry" /etc/os-release 2>/dev/null; then
                echo "raspios"
            else
                echo "linux"
            fi
            ;;
        FreeBSD)
            echo "freebsd"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

OS=$(detect_os)
echo "✅ Detected OS: $OS"

# Check for git
if ! command -v git &>/dev/null; then
    echo "❌ git is required. Please install git first."
    exit 1
fi

# Clone or update repo
if [ -d "$INSTALL_DIR/.git" ]; then
    echo "📦 Updating existing repo at $INSTALL_DIR..."
    git -C "$INSTALL_DIR" pull
else
    echo "📦 Cloning repo to $INSTALL_DIR..."
    git clone "$REPO" "$INSTALL_DIR"
fi

# Create log directory
case "$OS" in
    mac)
        LOG_DIR="$HOME/Documents/logs/mac"
        SCRIPT="$INSTALL_DIR/mac/update-mac"
        SHELL_RC="$HOME/.zprofile"
        PATH_ENTRY='export PATH="$HOME/scripts/mac:$HOME/scripts/common:$PATH"'
        ;;
    linux)
        LOG_DIR="$HOME/logs/linux"
        SCRIPT="$INSTALL_DIR/linux/update-linux.sh"
        SHELL_RC="$HOME/.bashrc"
        PATH_ENTRY='export PATH="$HOME/scripts/linux:$HOME/scripts/common:$PATH"'
        ;;
    raspios)
        LOG_DIR="$HOME/logs/raspios"
        SCRIPT="$INSTALL_DIR/raspios/update-raspi.sh"
        SHELL_RC="$HOME/.bashrc"
        PATH_ENTRY='export PATH="$HOME/scripts/raspios:$HOME/scripts/common:$PATH"'
        ;;
    freebsd)
        LOG_DIR="$HOME/logs/freebsd"
        SCRIPT="$INSTALL_DIR/freebsd/update-freebsd.sh"
        SHELL_RC="$HOME/.profile"
        PATH_ENTRY='export PATH="$HOME/scripts/freebsd:$HOME/scripts/common:$PATH"'
        ;;
    *)
        echo "❌ Unsupported OS. Exiting."
        exit 1
        ;;
esac

# Create log directory
mkdir -p "$LOG_DIR"
echo "✅ Log directory: $LOG_DIR"

# Make script executable
chmod +x "$SCRIPT"
echo "✅ Script ready: $SCRIPT"

# Add to PATH if not already there
if ! grep -q "scripts/$OS" "$SHELL_RC" 2>/dev/null; then
    echo "$PATH_ENTRY" >> "$SHELL_RC"
    echo "✅ Added to PATH in $SHELL_RC"
else
    echo "✅ PATH already configured in $SHELL_RC"
fi

# Source shell config
# shellcheck disable=SC1090
source "$SHELL_RC" 2>/dev/null || true

echo ""
echo "============================================================"
echo "✅ Installation complete!"
echo ""
echo "Run your update script with:"

case "$OS" in
    mac)     echo "  update-mac" ;;
    linux)   echo "  update-linux" ;;
    raspios) echo "  update-raspi" ;;
    freebsd) echo "  update-freebsd" ;;
esac

echo ""
echo "Reload your shell first if the command is not found:"
echo "  source $SHELL_RC"
echo "============================================================"
