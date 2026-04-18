# system-update-automation

Cross-platform system maintenance, update, and major version upgrade automation scripts.
Covers desktops, servers, NAS devices, firewalls, routers, and hypervisors.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## Supported Platforms

| Category | Platform | Script | Min Version |
|---|---|---|---|
| **Desktop** | macOS | `mac/update-mac` | macOS 12 (Monterey) |
| **Desktop** | Windows | `windows/update-windows.ps1` | Windows 10 1903 / Windows 11 |
| **Linux** | Debian / Ubuntu / Mint | `linux/debian/update-debian.sh` | Debian 10 / Ubuntu 20.04 |
| **Linux** | Arch / Manjaro / EndeavourOS | `linux/arch/update-arch.sh` | Any current Arch |
| **Linux** | RHEL / Fedora / Rocky / Alma | `linux/rhel/update-rhel.sh` | RHEL 8 / Fedora 33 |
| **Linux** | Alpine | `linux/alpine/update-alpine.sh` | Alpine 3.12 |
| **Linux** | Generic (auto-detect) | `linux/update-linux.sh` | apt / dnf / pacman / zypper |
| **SBC** | Raspberry Pi OS | `raspios/update-raspi.sh` | Pi OS Buster (10) |
| **BSD** | FreeBSD | `freebsd/update-freebsd.sh` | FreeBSD 12.0 |
| **NAS** | QNAP | `nas/update-qnap.sh` | QTS 4.5 |
| **NAS** | Synology | `nas/update-synology.sh` | DSM 6.2 |
| **NAS** | Unraid | `nas/update-unraid.sh` | Unraid 6.9 |
| **NAS** | TrueNAS SCALE/CORE | `nas/update-truenas.sh` | SCALE 22.x / CORE 13 |
| **Firewall** | OPNsense | `firewall/update-opnsense.sh` | OPNsense 21.1 |
| **Firewall** | pfSense | `firewall/update-pfsense.sh` | pfSense 2.5 |
| **Router** | OpenWrt | `router/update-openwrt.sh` | OpenWrt 19.07 |
| **Router** | DD-WRT | `router/update-ddwrt.sh` | Any with BusyBox |
| **Hypervisor** | Proxmox VE | `hypervisor/update-proxmox.sh` | PVE 7.0 |
| **Hypervisor** | ESXi | `hypervisor/update-esxi.sh` | ESXi 6.7 |

## Major Version Upgrade Scripts

| Platform | Script | Method |
|---|---|---|
| Debian / Ubuntu | `upgrade/upgrade-debian.sh` | sources.list repoint / do-release-upgrade |
| RHEL / Fedora / Rocky / Alma | `upgrade/upgrade-rhel.sh` | dnf system-upgrade / leapp |
| FreeBSD | `upgrade/upgrade-freebsd.sh` | freebsd-update upgrade (2-reboot process) |
| Alpine Linux | `upgrade/upgrade-alpine.sh` | repo branch switch + apk upgrade |

See `docs/UPGRADE-GUIDE.md` before running any upgrade script.

---

## Repository Structure

    system-update-automation/
    ├── mac/
    │   └── update-mac
    ├── windows/
    │   ├── update-windows.ps1
    │   └── self-update.ps1
    ├── linux/
    │   ├── update-linux.sh
    │   ├── debian/update-debian.sh
    │   ├── arch/update-arch.sh
    │   ├── rhel/update-rhel.sh
    │   └── alpine/update-alpine.sh
    ├── raspios/
    │   └── update-raspi.sh
    ├── freebsd/
    │   └── update-freebsd.sh
    ├── nas/
    │   ├── update-qnap.sh
    │   ├── update-synology.sh
    │   ├── update-unraid.sh
    │   └── update-truenas.sh
    ├── firewall/
    │   ├── update-opnsense.sh
    │   └── update-pfsense.sh
    ├── router/
    │   ├── update-openwrt.sh
    │   └── update-ddwrt.sh
    ├── hypervisor/
    │   ├── update-proxmox.sh
    │   └── update-esxi.sh
    ├── upgrade/
    │   ├── upgrade-debian.sh
    │   ├── upgrade-rhel.sh
    │   ├── upgrade-freebsd.sh
    │   └── upgrade-alpine.sh
    ├── common/
    │   └── utils.sh
    ├── docs/
    │   ├── HOMEBREW-APPS.md
    │   ├── WINDOWS-SETUP.md
    │   ├── VERSION-REQUIREMENTS.md
    │   └── UPGRADE-GUIDE.md
    ├── self-update.sh
    ├── install.sh
    ├── CHANGELOG.md
    └── README.md

---

## Quick Install

### Mac / Linux / Raspberry Pi / FreeBSD

    curl -fsSL https://raw.githubusercontent.com/pawlisko80/system-update-automation/main/install.sh | bash

Auto-detects your OS and sets up the correct script and PATH.

### Windows

    git clone https://github.com/pawlisko80/system-update-automation.git C:\scripts

Run as Administrator in PowerShell:

    C:\scripts\windows\update-windows.ps1

See `docs/WINDOWS-SETUP.md` for full prerequisites.

---

## Manual Installation

### macOS

    git clone https://github.com/pawlisko80/system-update-automation.git ~/scripts
    mkdir -p ~/Documents/logs/mac
    chmod +x ~/scripts/mac/update-mac
    echo 'export PATH="$HOME/scripts/mac:$HOME/scripts/common:$PATH"' >> ~/.zprofile
    source ~/.zprofile

Prerequisites:

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    brew install mas

### Linux (Debian/Ubuntu)

    git clone https://github.com/pawlisko80/system-update-automation.git ~/scripts
    mkdir -p ~/logs/debian
    chmod +x ~/scripts/linux/debian/update-debian.sh
    echo 'export PATH="$HOME/scripts/linux/debian:$HOME/scripts/common:$PATH"' >> ~/.bashrc
    source ~/.bashrc

### NAS / Firewall / Router / Hypervisor

SSH into your device and download directly:

    curl -fsSL https://raw.githubusercontent.com/pawlisko80/system-update-automation/main/nas/update-qnap.sh -o ~/update-qnap.sh
    chmod +x ~/update-qnap.sh && ~/update-qnap.sh

Replace `nas/update-qnap.sh` with the appropriate script for your device.

---

## Usage

### Daily maintenance

| Platform | Command |
|---|---|
| macOS | `update-mac` |
| Windows | `C:\scripts\windows\update-windows.ps1` (as Admin) |
| Linux Debian | `update-debian` |
| Linux Arch | `update-arch` |
| Linux RHEL | `update-rhel` |
| Linux Alpine | `update-alpine` |
| Linux generic | `update-linux` |
| Raspberry Pi | `update-raspi` |
| FreeBSD | `update-freebsd` |
| NAS/Firewall/Router | `~/update-<platform>.sh` (via SSH) |

### Self-update (pull latest scripts from GitHub)

    # Mac/Linux
    ~/scripts/self-update.sh

    # Windows (as Administrator)
    C:\scripts\windows\self-update.ps1

The update scripts prompt automatically every 7 days to check for script updates.
Change the interval at the top of each script:

    # Mac (update-mac)
    SELF_UPDATE_INTERVAL_DAYS=7

    # Windows (update-windows.ps1)
    $SelfUpdateIntervalDays = 7

### Major version upgrades

    # Always read the guide first
    cat ~/scripts/docs/UPGRADE-GUIDE.md

    # Then run the appropriate upgrade script
    ~/scripts/upgrade/upgrade-debian.sh
    ~/scripts/upgrade/upgrade-rhel.sh
    ~/scripts/upgrade/upgrade-freebsd.sh
    ~/scripts/upgrade/upgrade-alpine.sh

---

## Features

- Auto-detects package manager on generic Linux (apt/dnf/pacman/zypper)
- Auto-detects Raspberry Pi model (rpi-eeprom only on Pi 4/5)
- Auto-detects TrueNAS SCALE vs CORE
- Auto-detects Windows architecture (ARM64 vs AMD64)
- Docker container image updates on all NAS/hypervisor platforms
- ZFS pool status on TrueNAS and Proxmox
- Disk SMART health check on all server/NAS platforms
- WireGuard tunnel status on OPNsense
- AUR support on Arch (yay/paru auto-detected)
- Firmware updates via fwupd on Debian/Arch/RHEL
- Config backup on OpenWrt before updates
- Version checks with clear error messages on all platforms
- Interactive prompts before OS/firmware updates — never auto-reboots
- Gracefully skips missing optional tools
- Self-update with 7-day interval check and local change backup
- Shared utility library in `common/utils.sh`
- Persistent append-only logs with timestamped separators

---

## Windows ARM64 Notes

| Feature | Behavior |
|---|---|
| Windows Update | Native COM API (PSWindowsUpdate broken on ARM64) |
| Microsoft Edge | Pinned in winget — updated via Microsoft AutoUpdate |
| Architecture detection | Automatic via `$env:PROCESSOR_ARCHITECTURE` |

---

## Known Limitations

| Platform | Limitation |
|---|---|
| MakeMKV | Homebrew cask deprecated Sept 2026 |
| VMware Fusion | Homebrew cask disabled — requires Broadcom login |
| Samsung Magician | Manual installer cask — open app to update |
| DD-WRT | Logs in /tmp (RAM) — lost on reboot |
| ESXi | Online depot requires ESXi internet access |
| CentOS 7 | Uses yum not dnf — not supported, migrate to Rocky/Alma |

---

## Documentation

| File | Description |
|---|---|
| `docs/HOMEBREW-APPS.md` | Complete list of Homebrew-managed macOS apps |
| `docs/WINDOWS-SETUP.md` | Windows prerequisites and setup guide |
| `docs/VERSION-REQUIREMENTS.md` | Minimum supported versions for all platforms |
| `docs/UPGRADE-GUIDE.md` | Major version upgrade guide and checklists |
| `CHANGELOG.md` | Full version history |

---

## License

MIT
