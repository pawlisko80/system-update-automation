#!/bin/bash
# =============================================================
# mqtt-common.sh - MQTT and reporting helper functions
# Source this file from other scripts to enable MQTT reporting
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

# Load .env.local if it exists
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_LOCAL="$SCRIPTS_DIR/.env.local"

if [ -f "$ENV_LOCAL" ]; then
    # shellcheck disable=SC1090
    source "$ENV_LOCAL"
fi

# Set device name from hostname if not configured
DEVICE_NAME="${DEVICE_NAME:-$(hostname | cut -d. -f1 | tr '[:upper:]' '[:lower:]' | tr ' ' '-')}"

# =============================================================
# Check if MQTT is available and configured
# =============================================================
mqtt_available() {
    if [ -z "$MQTT_BROKER" ]; then
        return 1  # not configured
    fi
    if ! command -v mosquitto_pub &>/dev/null; then
        return 1  # not installed
    fi
    return 0
}

# =============================================================
# Publish a single MQTT message
# Usage: mqtt_publish "topic/path" "message"
# =============================================================
mqtt_publish() {
    local topic="$1"
    local message="$2"

    if ! mqtt_available; then
        return 0  # silently skip if not configured
    fi

    local full_topic="${MQTT_TOPIC_PREFIX:-homelab}/$DEVICE_NAME/$topic"
    local port="${MQTT_PORT:-1883}"

    if [ -n "$MQTT_USERNAME" ] && [ -n "$MQTT_PASSWORD" ]; then
        mosquitto_pub \
            -h "$MQTT_BROKER" \
            -p "$port" \
            -u "$MQTT_USERNAME" \
            -P "$MQTT_PASSWORD" \
            -t "$full_topic" \
            -m "$message" \
            -q 1 \
            >/dev/null 2>&1
    else
        mosquitto_pub \
            -h "$MQTT_BROKER" \
            -p "$port" \
            -t "$full_topic" \
            -m "$message" \
            -q 1 \
            >/dev/null 2>&1
    fi
}

# =============================================================
# Publish update result to MQTT
# Usage: mqtt_report_update "success|failed" "2 packages updated"
# =============================================================
mqtt_report_update() {
    local mqtt_status="$1"
    local summary="$2"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    local payload
    payload=$(cat << JSON
{
  "device": "$DEVICE_NAME",
  "type": "update",
  "status": "$mqtt_status",
  "summary": "$summary",
  "timestamp": "$timestamp",
  "location": "${DEVICE_LOCATION:-unknown}"
}
JSON
)
    mqtt_publish "update/status" "$payload"
    mqtt_publish "update/last_run" "$timestamp"
    mqtt_publish "update/result" "$mqtt_status"
}

# =============================================================
# Publish health check result to MQTT
# Usage: mqtt_report_health "0" "disk=73%,memory=64%,cpu=5%"
# =============================================================
mqtt_report_health() {
    local issues="$1"
    local metrics="$2"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    local mqtt_status="ok"
    if [ "$issues" -gt 0 ]; then
        status="warning"
    fi

    local payload
    payload=$(cat << JSON
{
  "device": "$DEVICE_NAME",
  "type": "health",
  "status": "$mqtt_status",
  "issues": $issues,
  "metrics": "$metrics",
  "timestamp": "$timestamp",
  "location": "${DEVICE_LOCATION:-unknown}"
}
JSON
)
    mqtt_publish "health/status" "$payload"
    mqtt_publish "health/issues" "$issues"
    mqtt_publish "health/last_run" "$timestamp"
}

# =============================================================
# Publish disk usage to MQTT
# Usage: mqtt_report_disk "/dev/disk0" "73"
# =============================================================
mqtt_report_disk() {
    local disk="$1"
    local percent="$2"
    mqtt_publish "health/disk_$(echo "$disk" | tr '/' '_' | sed 's/^_//')" "$percent"
}

# =============================================================
# Publish network check result to MQTT
# Usage: mqtt_report_network "7" "8" "3 down: switch,nas,proxmox"
# =============================================================
mqtt_report_network() {
    local up="$1"
    local total="$2"
    local summary="$3"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    local mqtt_status="ok"
    if [ "$up" -lt "$total" ]; then
        status="warning"
    fi

    local payload
    payload=$(cat << JSON
{
  "device": "$DEVICE_NAME",
  "type": "network",
  "status": "$mqtt_status",
  "hosts_up": $up,
  "hosts_total": $total,
  "summary": "$summary",
  "timestamp": "$timestamp"
}
JSON
)
    mqtt_publish "network/status" "$payload"
    mqtt_publish "network/hosts_up" "$up"
    mqtt_publish "network/hosts_total" "$total"
}

# =============================================================
# HTTP POST fallback (if STATUS_SERVER_URL is set)
# =============================================================
http_report() {
    local payload="$1"

    if [ -z "$STATUS_SERVER_URL" ]; then
        return 0  # not configured
    fi

    if ! command -v curl &>/dev/null; then
        return 0
    fi

    if [ -n "$STATUS_SERVER_TOKEN" ]; then
        curl -s -X POST "$STATUS_SERVER_URL" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $STATUS_SERVER_TOKEN" \
            -d "$payload" \
            >/dev/null 2>&1
    else
        curl -s -X POST "$STATUS_SERVER_URL" \
            -H "Content-Type: application/json" \
            -d "$payload" \
            >/dev/null 2>&1
    fi
}
