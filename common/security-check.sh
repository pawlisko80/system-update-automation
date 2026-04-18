#!/bin/bash
# =============================================================
# security-check.sh — Security audit script
# Covers: failed logins, open ports, firewall, updates, users
# Platforms: Linux, macOS
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

LOG_DIR="$HOME/logs/security"
LOG_FILE="$LOG_DIR/security-$(date +%Y%m%d-%H%M%S).log"
ISSUES=0
mkdir -p "$LOG_DIR"

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

ok()      { echo -e "${GREEN}  ✅ $1${NC}" | tee -a "$LOG_FILE"; }
warn()    { echo -e "${YELLOW}  ⚠️  $1${NC}" | tee -a "$LOG_FILE"; ISSUES=$((ISSUES+1)); }
crit()    { echo -e "${RED}  ❌ $1${NC}" | tee -a "$LOG_FILE"; ISSUES=$((ISSUES+1)); }
info()    { echo -e "${BLUE}  ℹ️  $1${NC}" | tee -a "$LOG_FILE"; }
section() { echo "" | tee -a "$LOG_FILE"; echo -e "${BLUE}━━━ $1 ━━━${NC}" | tee -a "$LOG_FILE"; }

OS=$(uname -s)

echo "============================================================" | tee -a "$LOG_FILE"
echo "  Security Check — $(date)" | tee -a "$LOG_FILE"
echo "  Host: $(hostname)" | tee -a "$LOG_FILE"
echo "============================================================" | tee -a "$LOG_FILE"

# =============================================================
# Failed SSH Login Attempts
# =============================================================
section "Failed Login Attempts"
if [ "$OS" = "Linux" ]; then
    if [ -f /var/log/auth.log ]; then
        FAILED=$(grep -c "Failed password" /var/log/auth.log 2>/dev/null || echo 0)
        INVALID=$(grep -c "Invalid user" /var/log/auth.log 2>/dev/null || echo 0)
        if [ "$FAILED" -gt 100 ] || [ "$INVALID" -gt 100 ]; then
            crit "High number of failed SSH attempts: $FAILED failed passwords, $INVALID invalid users"
        elif [ "$FAILED" -gt 10 ] || [ "$INVALID" -gt 10 ]; then
            warn "Failed SSH attempts: $FAILED failed passwords, $INVALID invalid users"
        else
            ok "Failed SSH attempts: $FAILED (last log rotation)"
        fi

        # Top attacking IPs
        if [ "$FAILED" -gt 0 ]; then
            info "Top source IPs:"
            grep "Failed password" /var/log/auth.log 2>/dev/null | \
                grep -oP 'from \K[\d.]+' | sort | uniq -c | sort -rn | head -5 | \
                while read -r count ip; do
                    echo "    $count attempts from $ip" | tee -a "$LOG_FILE"
                done
        fi
    elif [ -f /var/log/secure ]; then
        FAILED=$(grep -c "Failed password" /var/log/secure 2>/dev/null || echo 0)
        ok "Failed SSH attempts: $FAILED (last log rotation)"
    else
        info "Auth log not found — may need root access"
    fi
elif [ "$OS" = "Darwin" ]; then
    FAILED=$(log show --predicate 'process == "sshd"' --last 24h 2>/dev/null | grep -c "Failed\|Invalid" || echo 0)
    if [ "$FAILED" -gt 10 ]; then
        warn "Failed SSH/login attempts in last 24h: $FAILED"
    else
        ok "Failed login attempts (24h): $FAILED"
    fi
fi

# =============================================================
# Open Ports
# =============================================================
section "Open Ports"
if [ "$OS" = "Linux" ]; then
    if command -v ss &>/dev/null; then
        info "Listening ports:"
        ss -tlnp 2>/dev/null | tee -a "$LOG_FILE"

        # Check for unexpected ports
        UNEXPECTED_PORTS=$(ss -tlnp 2>/dev/null | grep -v "127.0.0.1\|::1" | \
            grep -v ":22 \|:80 \|:443 \|:8080 \|:8443" | tail -n +2)
        if [ -n "$UNEXPECTED_PORTS" ]; then
            warn "Ports open to network (verify these are expected):"
            echo "$UNEXPECTED_PORTS" | tee -a "$LOG_FILE"
        else
            ok "No unexpected open ports detected"
        fi
    fi
elif [ "$OS" = "Darwin" ]; then
    info "Listening ports:"
    netstat -an 2>/dev/null | grep LISTEN | tee -a "$LOG_FILE"
fi

# =============================================================
# Firewall Status
# =============================================================
section "Firewall"
if [ "$OS" = "Linux" ]; then
    if command -v ufw &>/dev/null; then
        STATUS=$(ufw status 2>/dev/null | head -1)
        if echo "$STATUS" | grep -q "active"; then
            ok "ufw firewall: $STATUS"
        else
            crit "ufw firewall: $STATUS"
        fi
    elif command -v firewall-cmd &>/dev/null; then
        STATUS=$(firewall-cmd --state 2>/dev/null)
        if [ "$STATUS" = "running" ]; then
            ok "firewalld: $STATUS"
        else
            crit "firewalld: $STATUS"
        fi
    elif command -v iptables &>/dev/null; then
        RULES=$(iptables -L 2>/dev/null | grep -c "^ACCEPT\|^DROP\|^REJECT" || echo 0)
        if [ "$RULES" -gt 0 ]; then
            ok "iptables: $RULES rules active"
        else
            warn "iptables: no rules detected"
        fi
    else
        warn "No firewall detected (ufw/firewalld/iptables)"
    fi
elif [ "$OS" = "Darwin" ]; then
    FW_STATUS=$(defaults read /Library/Preferences/com.apple.alf globalstate 2>/dev/null)
    case "$FW_STATUS" in
        0) warn "macOS firewall: disabled" ;;
        1) ok "macOS firewall: enabled (block unauthorized)" ;;
        2) ok "macOS firewall: enabled (essential services only)" ;;
        *) info "macOS firewall: status unknown" ;;
    esac
fi

# =============================================================
# Pending Security Updates
# =============================================================
section "Security Updates"
if [ "$OS" = "Linux" ]; then
    if command -v apt &>/dev/null; then
        SECURITY=$(apt list --upgradable 2>/dev/null | grep -c "security" || echo 0)
        if [ "$SECURITY" -gt 0 ]; then
            warn "$SECURITY security update(s) pending"
            apt list --upgradable 2>/dev/null | grep "security" | tee -a "$LOG_FILE"
        else
            ok "No pending security updates"
        fi
    elif command -v dnf &>/dev/null; then
        SECURITY=$(dnf updateinfo list security 2>/dev/null | grep -c "Important\|Critical" || echo 0)
        if [ "$SECURITY" -gt 0 ]; then
            warn "$SECURITY important/critical security updates pending"
        else
            ok "No critical security updates pending"
        fi
    fi
elif [ "$OS" = "Darwin" ]; then
    UPDATES=$(softwareupdate -l 2>&1 | grep -c "Label:" || echo 0)
    if [ "$UPDATES" -gt 0 ]; then
        warn "$UPDATES system update(s) pending"
    else
        ok "macOS is up to date"
    fi
fi

# =============================================================
# User Accounts
# =============================================================
section "User Accounts"
if [ "$OS" = "Linux" ]; then
    # Users with UID 0 (root)
    ROOT_USERS=$(awk -F: '$3==0{print $1}' /etc/passwd 2>/dev/null)
    ROOT_COUNT=$(echo "$ROOT_USERS" | wc -l | tr -d ' ')
    if [ "$ROOT_COUNT" -gt 1 ]; then
        warn "Multiple root-level users: $ROOT_USERS"
    else
        ok "Only one root user: $ROOT_USERS"
    fi

    # Users with login shells
    info "Users with login shells:"
    grep -v "nologin\|false" /etc/passwd 2>/dev/null | cut -d: -f1,7 | tee -a "$LOG_FILE"

    # Sudo users
    if [ -f /etc/sudoers ]; then
        info "Sudo configuration:"
        grep -v "^#\|^$" /etc/sudoers 2>/dev/null | grep -v "Defaults\|root" | tee -a "$LOG_FILE"
    fi
fi

# =============================================================
# SSH Configuration
# =============================================================
section "SSH Configuration"
SSH_CONFIG="/etc/ssh/sshd_config"
if [ -f "$SSH_CONFIG" ]; then
    # Root login
    ROOT_LOGIN=$(grep "^PermitRootLogin" "$SSH_CONFIG" 2>/dev/null | awk '{print $2}')
    if [ "$ROOT_LOGIN" = "yes" ]; then
        crit "SSH root login is ENABLED (PermitRootLogin yes)"
    elif [ -z "$ROOT_LOGIN" ]; then
        warn "SSH PermitRootLogin not explicitly set (default may allow root)"
    else
        ok "SSH root login: $ROOT_LOGIN"
    fi

    # Password auth
    PASS_AUTH=$(grep "^PasswordAuthentication" "$SSH_CONFIG" 2>/dev/null | awk '{print $2}')
    if [ "$PASS_AUTH" = "yes" ] || [ -z "$PASS_AUTH" ]; then
        warn "SSH password authentication enabled — consider key-only auth"
    else
        ok "SSH password authentication: $PASS_AUTH"
    fi

    # Port
    SSH_PORT=$(grep "^Port" "$SSH_CONFIG" 2>/dev/null | awk '{print $2}')
    if [ -z "$SSH_PORT" ]; then
        info "SSH port: 22 (default)"
    else
        info "SSH port: $SSH_PORT"
    fi
else
    info "SSH config not found at $SSH_CONFIG"
fi

# =============================================================
# Secrets Scanner
# =============================================================
section "Secrets Scan (scripts folder)"
SCRIPTS_DIR="$HOME/scripts"
if [ -d "$SCRIPTS_DIR" ]; then
    info "Scanning $SCRIPTS_DIR for potential secrets..."
    FOUND=0

    # Common patterns to check
    PATTERNS=(
        "password\s*=\s*['\"][^'\"]\+"
        "api[_-]key\s*=\s*['\"][^'\"]\+"
        "secret\s*=\s*['\"][^'\"]\+"
        "token\s*=\s*['\"][^'\"]\+"
        "aws_access_key_id"
        "PRIVATE KEY"
    )

    for pattern in "${PATTERNS[@]}"; do
        MATCHES=$(grep -rin "$pattern" "$SCRIPTS_DIR" 2>/dev/null | \
            grep -v ".git\|CHANGELOG\|README\|notify.sh" | head -5)
        if [ -n "$MATCHES" ]; then
            warn "Potential secret found (pattern: $pattern):"
            echo "$MATCHES" | tee -a "$LOG_FILE"
            FOUND=$((FOUND+1))
        fi
    done

    if [ "$FOUND" -eq 0 ]; then
        ok "No obvious secrets found in scripts folder"
    fi
else
    info "Scripts folder not found at $SCRIPTS_DIR"
fi

# =============================================================
# Summary
# =============================================================
echo "" | tee -a "$LOG_FILE"
echo "============================================================" | tee -a "$LOG_FILE"
if [ "$ISSUES" -eq 0 ]; then
    echo -e "${GREEN}  ✅ Security check passed — no issues found${NC}" | tee -a "$LOG_FILE"
else
    echo -e "${RED}  ❌ Security check complete — $ISSUES issue(s) found${NC}" | tee -a "$LOG_FILE"
fi
echo "  Log saved to $LOG_FILE" | tee -a "$LOG_FILE"
echo "============================================================" | tee -a "$LOG_FILE"
echo ""
echo "Press ENTER to close..."
read -r
