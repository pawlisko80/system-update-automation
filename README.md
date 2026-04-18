# system-update-automation

Cross-platform system maintenance, update, and major version upgrade automation scripts.
Covers desktops, servers, NAS devices, firewalls, routers, and hypervisors.

---

## Supported Platforms

| Category | Platform | Script | Min Version |
|---|---|---|---|
| Desktop | macOS | mac/update-mac | macOS 12 (Monterey) |
| Desktop | Windows | windows/update-windows.ps1 | Windows 10 1903 / Windows 11 |
| Linux | Debian / Ubuntu / Mint | linux/debian/update-debian.sh | Debian 10 / Ubuntu 20.04 |
| Linux | Arch / Manjaro / EndeavourOS | linux/arch/update-arch.sh | Any current Arch |
| Linux | RHEL / Fedora / Rocky / Alma | linux/rhel/update-rhel.sh | RHEL 8 / Fedora 33 |
| Linux | Alpine | linux/alpine/update-alpine.sh | Alpine 3.12 |
| Linux | Generic (auto-detect) | linux/update-linux.sh | apt / dnf / pacman / zypper |
| SBC | Raspberry Pi OS | raspios/update-raspi.sh | Pi OS Buster (10) |
| BSD | FreeBSD | freebsd/update-freebsd.sh | FreeBSD 12.0 |
| NAS | QNAP | nas/update-qnap.sh | QTS 4.5 |
| NAS | Synology | nas/update-synology.sh | DSM 6.2 |
| NAS | Unraid | nas/update-unraid.sh | Unraid 6.9 |
| NAS | TrueNAS SCALE/CORE | nas/update-truenas.sh | SCALE 22.x / CORE 13 |
| Firewall | OPNsense | firewall/update-opnsense.sh | OPNsense 21.1 |
| Firewall | pfSense | firewall/update-pfsense.sh | pfSense 2.5 |
| Router | OpenWrt | router/update-openwrt.sh | OpenWrt 19.07 |
| Router | DD-WRT | router/update-ddwrt.sh | Any with BusyBox |
| Hypervisor | Proxmox VE | hypervisor/update-proxmox.sh | PVE 7.0 |
| Hypervisor | ESXi | hypervisor/update-esxi.sh | ESXi 6.7 |

---

## Repository Structure

    system-update-automation/
    |-- mac/
    |   |-- update-mac
    |   `-- menu
    |-- windows/
    |   |-- update-windows.ps1
    |   |-- self-update.ps1
    |   |-- cleanup-windows.ps1
    |   |-- menu.ps1
    |   |-- check-health.ps1
    |   |-- security-check.ps1
    |   |-- inventory.ps1
    |   `-- network-check.ps1
    |-- linux/
    |   |-- update-linux.sh
    |   |-- menu
    |   |-- debian/update-debian.sh
    |   |-- arch/update-arch.sh
    |   |-- rhel/update-rhel.sh
    |   `-- alpine/update-alpine.sh
    |-- raspios/
    |   |-- update-raspi.sh
    |   `-- menu
    |-- freebsd/
    |   |-- update-freebsd.sh
    |   `-- menu
    |-- nas/
    |   |-- update-qnap.sh
    |   |-- update-synology.sh
    |   |-- update-unraid.sh
    |   `-- update-truenas.sh
    |-- firewall/
    |   |-- update-opnsense.sh
    |   `-- update-pfsense.sh
    |-- router/
    |   |-- update-openwrt.sh
    |   `-- update-ddwrt.sh
    |-- hypervisor/
    |   |-- update-proxmox.sh
    |   `-- update-esxi.sh
    |-- upgrade/
    |   |-- upgrade-debian.sh
    |   |-- upgrade-rhel.sh
    |   |-- upgrade-freebsd.sh
    |   `-- upgrade-alpine.sh
    |-- common/
    |   |-- hosts.conf          <- homelab network config (shared by all platforms)
    |   |-- utils.sh
    |   |-- check-health.sh
    |   |-- security-check.sh
    |   |-- inventory.sh
    |   |-- network-check.sh
    |   |-- notify.sh
    |   `-- summarize-logs.sh
    |-- docs/
    |   |-- HOMEBREW-APPS.md
    |   |-- WINDOWS-SETUP.md
    |   |-- VERSION-REQUIREMENTS.md
    |   `-- UPGRADE-GUIDE.md
    |-- self-update.sh
    |-- install.sh
    |-- CHANGELOG.md
    `-- README.md

---

## Quick Install

### Mac / Linux / Raspberry Pi / FreeBSD

    curl -fsSL https://raw.githubusercontent.com/pawlisko80/system-update-automation/main/install.sh | bash

### Windows

    git clone https://github.com/pawlisko80/system-update-automation.git C:\scripts

Run as Administrator in PowerShell:

    C:\scripts\windows\update-windows.ps1

See docs/WINDOWS-SETUP.md for full prerequisites.

---

## Interactive Menus

Every platform has an interactive menu with all maintenance options:

| Platform | Command |
|---|---|
| macOS | menu |
| Linux | menu |
| Raspberry Pi | menu |
| FreeBSD | menu |
| Windows | C:\scripts\windows\menu.ps1 (as Admin) |

### Menu Options

    1  Run system update
    2  Self-update scripts from GitHub
    3  Cleanup (Windows: temp files, cache, recycle bin)
    4  System health check
    5  Security audit
    6  System inventory
    7  Network topology check
    8  Summarize update logs (30 days)
    9 / q  Quit

---

## Network Configuration

Homelab devices are configured in a single shared file: common/hosts.conf

    # Format: IP|Name|Description
    10.20.30.1|router|OPNsense Router
    10.20.30.3|switch|Core Switch
    10.20.30.30|nas|QNAP NAS
    10.20.30.33|homeassistant|Home Assistant

Both common/network-check.sh (Mac/Linux) and windows/network-check.ps1 (Windows) read from
this file automatically. To add a new device:

1. Edit common/hosts.conf
2. git commit and git push
3. All platforms pick it up on next git pull

---

## Self-Update

Scripts check GitHub for updates every 7 days and prompt Y/N before pulling:

    # Mac/Linux
    ~/scripts/self-update.sh

    # Windows (as Administrator)
    C:\scripts\windows\self-update.ps1

Change the interval at the top of each update script:

    # Mac (update-mac)
    SELF_UPDATE_INTERVAL_DAYS=7

    # Windows (update-windows.ps1)
    $SelfUpdateIntervalDays = 7

---

## Major Version Upgrades

| Platform | Script | Method |
|---|---|---|
| Debian / Ubuntu | upgrade/upgrade-debian.sh | sources.list repoint / do-release-upgrade |
| RHEL / Fedora / Rocky / Alma | upgrade/upgrade-rhel.sh | dnf system-upgrade / leapp |
| FreeBSD | upgrade/upgrade-freebsd.sh | freebsd-update upgrade (2-reboot process) |
| Alpine Linux | upgrade/upgrade-alpine.sh | repo branch switch + apk upgrade |

Always read docs/UPGRADE-GUIDE.md before running any upgrade script.

---

## Notifications

Configure common/notify.sh with your preferred channels:

| Service | Setup |
|---|---|
| Slack | Set NOTIFY_SLACK_WEBHOOK |
| Discord | Set NOTIFY_DISCORD_WEBHOOK |
| ntfy.sh | Set NOTIFY_NTFY_TOPIC (free, no account needed) |
| Pushover | Set NOTIFY_PUSHOVER_TOKEN and NOTIFY_PUSHOVER_USER |
| Email | Set NOTIFY_EMAIL (requires sendmail/msmtp) |

Test with: bash ~/scripts/common/notify.sh

---

## Windows ARM64 Notes

| Feature | Behavior |
|---|---|
| Windows Update | Native COM API (PSWindowsUpdate broken on ARM64) |
| Microsoft Edge | Pinned in winget - updated via Microsoft AutoUpdate |
| Architecture detection | Automatic via $env:PROCESSOR_ARCHITECTURE |
| Common scripts | Native PS1 versions in windows/ folder (no Git Bash needed) |

---

## Known Limitations

| Platform | Limitation |
|---|---|
| MakeMKV | Homebrew cask deprecated Sept 2026 |
| VMware Fusion | Homebrew cask disabled - requires Broadcom login |
| Samsung Magician | Manual installer cask - open app to update |
| DD-WRT | Logs in /tmp (RAM) - lost on reboot |
| ESXi | Online depot requires internet access |
| CentOS 7 | Uses yum not dnf - not supported, migrate to Rocky/Alma |

---

## Documentation

| File | Description |
|---|---|
| common/hosts.conf | Homelab network device configuration |
| docs/HOMEBREW-APPS.md | Complete list of Homebrew-managed macOS apps |
| docs/WINDOWS-SETUP.md | Windows prerequisites and setup guide |
| docs/VERSION-REQUIREMENTS.md | Minimum supported versions for all platforms |
| docs/UPGRADE-GUIDE.md | Major version upgrade guide and checklists |
| CHANGELOG.md | Full version history |

---

## License

MIT
