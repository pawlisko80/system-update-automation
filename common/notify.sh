#!/bin/bash
# =============================================================
# notify.sh — Send notifications after updates/health checks
# Supports: Slack, Discord, ntfy.sh, Pushover, email (sendmail)
# Source this file or call notify_send from other scripts
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

# =============================================================
# Configuration — set your preferred notification method(s)
# Leave empty to disable that method
# =============================================================

# Slack webhook URL
# Get from: Slack → Apps → Incoming Webhooks
NOTIFY_SLACK_WEBHOOK=""

# Discord webhook URL
# Get from: Discord → Server Settings → Integrations → Webhooks
NOTIFY_DISCORD_WEBHOOK=""

# ntfy.sh topic (free, no account needed for basic use)
# Usage: set topic name, messages go to ntfy.sh/<topic>
# App: https://ntfy.sh
NOTIFY_NTFY_TOPIC=""

# Pushover (requires account + app token)
NOTIFY_PUSHOVER_TOKEN=""
NOTIFY_PUSHOVER_USER=""

# Email (requires sendmail/msmtp configured)
NOTIFY_EMAIL=""

# =============================================================
# Core notification function
# Usage: notify_send "Title" "Message" [priority]
# Priority: info (default), warning, critical
# =============================================================
notify_send() {
    local title="$1"
    local message="$2"
    local priority="${3:-info}"
    local hostname
    hostname=$(hostname)
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local full_message="[$hostname] $message"

    # Emoji based on priority
    case "$priority" in
        warning)  local emoji="⚠️" ;;
        critical) local emoji="❌" ;;
        *)        local emoji="✅" ;;
    esac

    local sent=0

    # Slack
    if [ -n "$NOTIFY_SLACK_WEBHOOK" ]; then
        curl -s -X POST "$NOTIFY_SLACK_WEBHOOK" \
            -H 'Content-type: application/json' \
            -d "{\"text\": \"$emoji *$title*\n$full_message\"}" \
            >/dev/null 2>&1 && sent=$((sent+1))
    fi

    # Discord
    if [ -n "$NOTIFY_DISCORD_WEBHOOK" ]; then
        curl -s -X POST "$NOTIFY_DISCORD_WEBHOOK" \
            -H 'Content-type: application/json' \
            -d "{\"content\": \"$emoji **$title**\n$full_message\"}" \
            >/dev/null 2>&1 && sent=$((sent+1))
    fi

    # ntfy.sh
    if [ -n "$NOTIFY_NTFY_TOPIC" ]; then
        local ntfy_priority="default"
        case "$priority" in
            warning)  ntfy_priority="high" ;;
            critical) ntfy_priority="urgent" ;;
        esac
        curl -s \
            -H "Title: $title" \
            -H "Priority: $ntfy_priority" \
            -H "Tags: $emoji" \
            -d "$full_message" \
            "https://ntfy.sh/$NOTIFY_NTFY_TOPIC" \
            >/dev/null 2>&1 && sent=$((sent+1))
    fi

    # Pushover
    if [ -n "$NOTIFY_PUSHOVER_TOKEN" ] && [ -n "$NOTIFY_PUSHOVER_USER" ]; then
        local pushover_priority=0
        case "$priority" in
            warning)  pushover_priority=0 ;;
            critical) pushover_priority=1 ;;
        esac
        curl -s \
            -F "token=$NOTIFY_PUSHOVER_TOKEN" \
            -F "user=$NOTIFY_PUSHOVER_USER" \
            -F "title=$title" \
            -F "message=$full_message" \
            -F "priority=$pushover_priority" \
            https://api.pushover.net/1/messages.json \
            >/dev/null 2>&1 && sent=$((sent+1))
    fi

    # Email
    if [ -n "$NOTIFY_EMAIL" ] && command -v sendmail &>/dev/null; then
        echo -e "Subject: $emoji $title\nFrom: system-update@$hostname\nTo: $NOTIFY_EMAIL\n\n$full_message\n\nTimestamp: $timestamp" \
            | sendmail "$NOTIFY_EMAIL" 2>/dev/null && sent=$((sent+1))
    fi

    if [ "$sent" -gt 0 ]; then
        echo "📣 Notification sent via $sent channel(s)"
    else
        echo "ℹ️  No notification channels configured (edit common/notify.sh)"
    fi
}

# =============================================================
# Convenience wrappers
# =============================================================
notify_info()     { notify_send "$1" "$2" "info"; }
notify_warning()  { notify_send "$1" "$2" "warning"; }
notify_critical() { notify_send "$1" "$2" "critical"; }

# =============================================================
# Update summary notification
# Usage: notify_update_summary "Mac" "2 packages updated, macOS up to date"
# =============================================================
notify_update_summary() {
    local platform="$1"
    local summary="$2"
    notify_send "Update complete: $platform" "$summary" "info"
}

# =============================================================
# Health alert notification
# Usage: notify_health_alert "3 issues found" "Disk /var 92% full, 2 failed services"
# =============================================================
notify_health_alert() {
    local issue_count="$1"
    local details="$2"
    if echo "$issue_count" | grep -q "^0"; then
        notify_send "Health check passed" "No issues found" "info"
    else
        notify_send "Health check: $issue_count" "$details" "warning"
    fi
}

# =============================================================
# Test notification
# Run this file directly to test: bash common/notify.sh
# =============================================================
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    echo "Testing notification channels..."
    notify_send "Test notification" "system-update-automation notification test" "info"
fi
