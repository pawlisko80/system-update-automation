#!/bin/bash
# =============================================================
# self-update.sh — Auto-update scripts from GitHub
# Updates all scripts in ~/scripts from the remote repo
# Safe: backs up local changes before pulling
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

SCRIPTS_DIR="$HOME/scripts"
REPO_URL="https://github.com/pawlisko80/system-update-automation.git"
BACKUP_DIR="$HOME/scripts-backup-$(date +%Y%m%d-%H%M%S)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_ok()   { echo -e "${GREEN}✅ $1${NC}"; }
print_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_err()  { echo -e "${RED}❌ $1${NC}"; }

echo "============================================================"
echo "  system-update-automation self-updater"
echo "============================================================"
echo ""

# Check git is available
if ! command -v git &>/dev/null; then
    print_err "git not found. Install git first."
    exit 1
fi

# Check scripts directory exists
if [ ! -d "$SCRIPTS_DIR" ]; then
    print_err "Scripts directory not found: $SCRIPTS_DIR"
    echo "Clone the repo first:"
    echo "  git clone $REPO_URL $SCRIPTS_DIR"
    exit 1
fi

# Check it's a git repo
if [ ! -d "$SCRIPTS_DIR/.git" ]; then
    print_err "$SCRIPTS_DIR is not a git repository."
    echo "Clone the repo first:"
    echo "  git clone $REPO_URL $SCRIPTS_DIR"
    exit 1
fi

cd "$SCRIPTS_DIR" || exit 1

# Check for local changes
LOCAL_CHANGES=$(git status --porcelain 2>/dev/null)
if [ -n "$LOCAL_CHANGES" ]; then
    print_warn "Local changes detected:"
    git status --short
    echo ""
    read -r -p "Back up local changes and continue? (y/N): " REPLY
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        echo "📦 Backing up to $BACKUP_DIR..."
        cp -r "$SCRIPTS_DIR" "$BACKUP_DIR"
        print_ok "Backup created at $BACKUP_DIR"
    else
        echo "Aborting. No changes made."
        exit 0
    fi
fi

# Fetch and check for updates
echo ""
echo "🔍 Checking for updates..."
git fetch origin 2>&1

LOCAL=$(git rev-parse HEAD 2>/dev/null)
REMOTE=$(git rev-parse origin/main 2>/dev/null)

if [ "$LOCAL" = "$REMOTE" ]; then
    print_ok "Already up to date. No updates available."
    echo ""
    echo "Current version: $(git log -1 --format='%h %s (%cr)' 2>/dev/null)"
    exit 0
fi

# Show what will change
echo ""
echo "📋 Updates available:"
git log HEAD..origin/main --oneline 2>/dev/null
echo ""

read -r -p "Apply updates? (y/N): " REPLY
if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
    echo "Aborting. No changes made."
    exit 0
fi

# Pull updates
echo ""
echo "⬆️  Pulling updates..."
git pull --rebase origin main 2>&1

if [ $? -ne 0 ]; then
    print_err "Update failed. Check git output above."
    if [ -d "$BACKUP_DIR" ]; then
        echo "Your backup is at: $BACKUP_DIR"
    fi
    exit 1
fi

# Fix permissions on all scripts
echo ""
echo "🔧 Fixing permissions..."
find "$SCRIPTS_DIR" -name "*.sh" -exec chmod +x {} \;
find "$SCRIPTS_DIR/mac" -name "update-mac" -exec chmod +x {} \; 2>/dev/null
find "$SCRIPTS_DIR/common" -name "*.sh" -exec chmod +x {} \; 2>/dev/null
chmod +x "$SCRIPTS_DIR/install.sh" 2>/dev/null

echo ""
print_ok "Update complete!"
echo ""
echo "Latest changes:"
git log -5 --oneline 2>/dev/null
echo ""
echo "============================================================"
