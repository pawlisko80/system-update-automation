#!/bin/bash
# =============================================================
# summarize-logs.sh — Parse update/health logs and generate report
# Shows last 30 days of activity across all platforms
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

LOG_BASE="$HOME/logs"
DAYS=30

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

section() { echo -e "\n${BLUE}━━━ $1 ━━━${NC}"; }
ok()   { echo -e "${GREEN}  ✅ $1${NC}"; }
warn() { echo -e "${YELLOW}  ⚠️  $1${NC}"; }

echo "============================================================"
echo "  Update & Health Summary — last $DAYS days"
echo "  Generated: $(date)"
echo "============================================================"

# =============================================================
# Mac update log
# =============================================================
MAC_LOG="$HOME/Documents/logs/mac/mac-update.log"
if [ -f "$MAC_LOG" ]; then
    section "macOS Updates"
    # Count runs
    RUNS=$(grep -c "Starting Mac update" "$MAC_LOG" 2>/dev/null || echo 0)
    ok "Total update runs: $RUNS"

    # Last run
    LAST_RUN=$(grep "Starting Mac update" "$MAC_LOG" 2>/dev/null | tail -1 | awk -F'] ' '{print $2}')
    ok "Last run: $LAST_RUN"

    # Count upgrades
    UPGRADES=$(grep -c "was successfully upgraded" "$MAC_LOG" 2>/dev/null || echo 0)
    ok "Total packages upgraded: $UPGRADES"

    # Recent upgrades
    echo "  Recent upgrades:"
    grep "was successfully upgraded" "$MAC_LOG" 2>/dev/null | tail -5 | while read -r line; do
        echo "    - $line"
    done

    # Check for errors
    ERRORS=$(grep -c "Error:\|ERROR:" "$MAC_LOG" 2>/dev/null || echo 0)
    if [ "$ERRORS" -gt 0 ]; then
        warn "Errors found: $ERRORS"
        grep "Error:\|ERROR:" "$MAC_LOG" 2>/dev/null | tail -3 | while read -r line; do
            echo "    $line"
        done
    fi
else
    echo "  No macOS update log found at $MAC_LOG"
fi

# =============================================================
# Health logs
# =============================================================
HEALTH_DIR="$LOG_BASE/health"
if [ -d "$HEALTH_DIR" ] && ls "$HEALTH_DIR"/*.log &>/dev/null 2>&1; then
    section "Health Checks"
    HEALTH_RUNS=$(ls "$HEALTH_DIR"/*.log 2>/dev/null | wc -l | tr -d ' ')
    ok "Total health check runs: $HEALTH_RUNS"

    LAST_HEALTH=$(ls -t "$HEALTH_DIR"/*.log 2>/dev/null | head -1)
    if [ -n "$LAST_HEALTH" ]; then
        ok "Last run: $(basename "$LAST_HEALTH")"
        ISSUES=$(grep -c "❌\|WARNING\|CRITICAL" "$LAST_HEALTH" 2>/dev/null || echo 0)
        if [ "$ISSUES" -gt 0 ]; then
            warn "Issues in last health check: $ISSUES"
            grep "❌\|WARNING\|CRITICAL" "$LAST_HEALTH" 2>/dev/null | tail -5 | while read -r line; do
                echo "    $line"
            done
        else
            ok "Last health check: no issues"
        fi
    fi
fi

# =============================================================
# Linux logs (if present)
# =============================================================
for platform in debian arch rhel alpine linux; do
    LOG_FILE="$LOG_BASE/$platform/${platform}-update.log"
    if [ -f "$LOG_FILE" ]; then
        section "$platform Updates"
        RUNS=$(grep -c "update started" "$LOG_FILE" 2>/dev/null || echo 0)
        ok "Total runs: $RUNS"
        LAST=$(grep "update started" "$LOG_FILE" 2>/dev/null | tail -1 | awk -F'] ' '{print $2}')
        ok "Last run: $LAST"
    fi
done

# =============================================================
# Git log — recent script changes
# =============================================================
SCRIPTS_DIR="$HOME/scripts"
if [ -d "$SCRIPTS_DIR/.git" ]; then
    section "Script Updates (GitHub)"
    cd "$SCRIPTS_DIR" || exit
    git log --oneline --since="$DAYS days ago" 2>/dev/null | while read -r line; do
        echo "  📝 $line"
    done
    COMMITS=$(git log --oneline --since="$DAYS days ago" 2>/dev/null | wc -l | tr -d ' ')
    ok "Script commits in last $DAYS days: $COMMITS"
fi

echo ""
echo "============================================================"
echo "  Report complete"
echo "============================================================"
echo ""
echo "Press ENTER to close..."
read -r
