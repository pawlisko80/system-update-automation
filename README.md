# system-update-automation

Cross-platform system maintenance and update automation scripts.
Covers desktops, servers, NAS devices, firewalls, hypervisors, routers, and embedded systems.

## Supported Platforms

| Category | Platform | Script | Package Managers / Sources |
|---|---|---|---|
| **Desktop** | macOS | `mac/update-mac` | Homebrew, mas (App Store) |
| **Desktop** | Windows | `windows/update-windows.ps1` | winget, Microsoft Store, Chocolatey |
| **Linux** | Debian / Ubuntu / Mint | `linux/debian/update-debian.sh` | apt, snap, flatpak, fwupd |
| **Linux** | Arch / Manjaro / EndeavourOS | `linux/arch/update-arch.sh` | pacman, yay/paru (AUR), flatpak |
| **Linux** | RHEL / Fedora / Rocky / Alma | `linux/rhel/update-rhel.sh` | dnf, flatpak, fwupd |
| **Linux** | Generic (auto-detect) | `linux/update-linux.sh` | apt, dnf, pacman, zypper |
| **Linux** | Alpine | `linux/alpine/update-alpine.sh` | apk |
| **SBC** | Raspberry Pi OS | `raspios/update-raspi.sh` | apt, rpi-update, rpi-eeprom |
| **BSD** | FreeBSD | `freebsd/update-freebsd.sh` | freebsd-update, pkg, ports |
| **NAS** | QNAP | `nas/update-qnap.sh` | Entware (opkg), Docker |
| **NAS** | Synology | `nas/update-synology.sh` | Entware (opkg/ipkg), Docker |
| **NAS** | Unraid | `nas/update-unraid.sh` | Docker, plugins, array check |
| **NAS** | TrueNAS SCALE/CORE | `nas/update-truenas.sh` | Apps/jails, Docker, ZFS |
| **Firewall** | OPNsense | `firewall/update-opnsense.sh` | pkg, firmware, plugins, WireGuard |
| **Firewall** | pfSense | `firewall/update-pfsense.sh` | pkg, packages |
| **Router** | OpenWrt | `router/update-openwrt.sh` | opkg, config backup |
| **Router** | DD-WRT | `router/update-ddwrt.sh` | opkg/ipkg (Optware/Entware) |
| **Hypervisor** | Proxmox VE | `hypervisor/update-proxmox.sh` | apt, pveupgrade, LXC templates |
| **Hypervisor** | ESXi | `hypervisor/update-esxi.sh` | esxcli, VIBs |

## Repository Structure

    system-update-automation/
    ├── mac/
    │   └── update-mac
    ├── windows/
    │   └── update-windows.ps1
    ├── linux/
    │   ├── update-linux.sh          # Generic auto-detect
    │   ├── debian/
    │   │   └── update-debian.sh
    │   ├── arch/
    │   │   └── update-arch.sh
    │   ├── rhel/
    │   │   └── update-rhel.sh
    │   └── alpine/
    │       └── update-alpine.sh
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
    ├── common/
    │   └── utils.sh
    ├── docs/
    │   ├── HOMEBREW-APPS.md
    │   └── WINDOWS-SETUP.md
    ├── install.sh
    └── README.md

## Quick Install (Mac/Linux/RasPi/FreeBSD)

    curl -fsSL https://raw.githubusercontent.com/pawlisko80/system-update-automation/main/install.sh | bash

The installer auto-detects your OS and sets up the correct script and PATH.

## Manual Installation

### macOS

    git clone https://github.com/pawlisko80/system-update-automation.git ~/scripts
    mkdir -p ~/Documents/logs/mac
    chmod +x ~/scripts/mac/update-mac
    echo 'export PATH="$HOME/scripts/mac:$HOME/scripts/common:$PATH"' >> ~/.zprofile
    source ~/.zprofile

Prerequisites: Homebrew, mas

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    brew install mas

### Windows

    git clone https://github.com/pawlisko80/system-update-automation.git C:\scripts

Run as Administrator in PowerShell:

    C:\scripts\windows\update-windows.ps1

See docs/WINDOWS-SETUP.md for full prerequisites and shortcut setup.

### Linux (Debian/Ubuntu/Mint)

    git clone https://github.com/pawlisko80/system-update-automation.git ~/scripts
    mkdir -p ~/logs/debian
    chmod +x ~/scripts/linux/debian/update-debian.sh
    echo 'export PATH="$HOME/scripts/linux/debian:$HOME/scripts/common:$PATH"' >> ~/.bashrc
    source ~/.bashrc

### Linux (Arch/Manjaro)

    git clone https://github.com/pawlisko80/system-update-automation.git ~/scripts
    mkdir -p ~/logs/arch
    chmod +x ~/scripts/linux/arch/update-arch.sh
    echo 'export PATH="$HOME/scripts/linux/arch:$HOME/scripts/common:$PATH"' >> ~/.bashrc
    source ~/.bashrc

### Linux (RHEL/Fedora/Rocky/Alma)

    git clone https://github.com/pawlisko80/system-update-automation.git ~/scripts
    mkdir -p ~/logs/rhel
    chmod +x ~/scripts/linux/rhel/update-rhel.sh
    echo 'export PATH="$HOME/scripts/linux/rhel:$HOME/scripts/common:$PATH"' >> ~/.bashrc
    source ~/.bashrc

### Alpine Linux

    git clone https://github.com/pawlisko80/system-update-automation.git ~/scripts
    mkdir -p ~/logs/alpine
    chmod +x ~/scripts/linux/alpine/update-alpine.sh
    echo 'export PATH="$HOME/scripts/linux/alpine:$HOME/scripts/common:$PATH"' >> ~/.profile
    source ~/.profile

### Raspberry Pi OS

    git clone https://github.com/pawlisko80/system-update-automation.git ~/scripts
    mkdir -p ~/logs/raspios
    chmod +x ~/scripts/raspios/update-raspi.sh
    echo 'export PATH="$HOME/scripts/raspios:$HOME/scripts/common:$PATH"' >> ~/.bashrc
    source ~/.bashrc

### FreeBSD

    git clone https://github.com/pawlisko80/system-update-automation.git ~/scripts
    mkdir -p ~/logs/freebsd
    chmod +x ~/scripts/freebsd/update-freebsd.sh
    echo 'export PATH="$HOME/scripts/freebsd:$HOME/scripts/common:$PATH"' >> ~/.profile
    source ~/.profile

### NAS Devices (QNAP / Synology / Unraid / TrueNAS)

SSH into your NAS, then download and run:

    # QNAP
    curl -fsSL https://raw.githubusercontent.com/pawlisko80/system-update-automation/main/nas/update-qnap.sh -o ~/update-qnap.sh
    chmod +x ~/update-qnap.sh && ~/update-qnap.sh

    # Synology
    curl -fsSL https://raw.githubusercontent.com/pawlisko80/system-update-automation/main/nas/update-synology.sh -o ~/update-synology.sh
    chmod +x ~/update-synology.sh && ~/update-synology.sh

    # Unraid
    curl -fsSL https://raw.githubusercontent.com/pawlisko80/system-update-automation/main/nas/update-unraid.sh -o ~/update-unraid.sh
    chmod +x ~/update-unraid.sh && ~/update-unraid.sh

    # TrueNAS
    curl -fsSL https://raw.githubusercontent.com/pawlisko80/system-update-automation/main/nas/update-truenas.sh -o ~/update-truenas.sh
    chmod +x ~/update-truenas.sh && ~/update-truenas.sh

### Firewalls (OPNsense / pfSense)

    # OPNsense
    curl -fsSL https://raw.githubusercontent.com/pawlisko80/system-update-automation/main/firewall/update-opnsense.sh -o ~/update-opnsense.sh
    chmod +x ~/update-opnsense.sh && ~/update-opnsense.sh

    # pfSense
    curl -fsSL https://raw.githubusercontent.com/pawlisko80/system-update-automation/main/firewall/update-pfsense.sh -o ~/update-pfsense.sh
    chmod +x ~/update-pfsense.sh && ~/update-pfsense.sh

### Routers (OpenWrt / DD-WRT)

    # OpenWrt
    curl -fsSL https://raw.githubusercontent.com/pawlisko80/system-update-automation/main/router/update-openwrt.sh -o /tmp/update-openwrt.sh
    chmod +x /tmp/update-openwrt.sh && /tmp/update-openwrt.sh

    # DD-WRT
    curl -fsSL https://raw.githubusercontent.com/pawlisko80/system-update-automation/main/router/update-ddwrt.sh -o /tmp/update-ddwrt.sh
    chmod +x /tmp/update-ddwrt.sh && /tmp/update-ddwrt.sh

### Hypervisors (Proxmox / ESXi)

    # Proxmox
    curl -fsSL https://raw.githubusercontent.com/pawlisko80/system-update-automation/main/hypervisor/update-proxmox.sh -o ~/update-proxmox.sh
    chmod +x ~/update-proxmox.sh && ~/update-proxmox.sh

    # ESXi
    curl -fsSL https://raw.githubusercontent.com/pawlisko80/system-update-automation/main/hypervisor/update-esxi.sh -o ~/update-esxi.sh
    chmod +x ~/update-esxi.sh && ~/update-esxi.sh

## Usage

| Platform | Command |
|---|---|
| macOS | `update-mac` |
| Linux (Debian) | `update-debian` |
| Linux (Arch) | `update-arch` |
| Linux (RHEL) | `update-rhel` |
| Linux (Alpine) | `update-alpine` |
| Linux (generic) | `update-linux` |
| Raspberry Pi | `update-raspi` |
| FreeBSD | `update-freebsd` |
| Windows | `update-windows` (as Administrator) |
| QNAP | `~/update-qnap.sh` (via SSH) |
| Synology | `~/update-synology.sh` (via SSH) |
| Unraid | `~/update-unraid.sh` (via SSH) |
| TrueNAS | `~/update-truenas.sh` (via SSH) |
| OPNsense | `~/update-opnsense.sh` (via SSH) |
| pfSense | `~/update-pfsense.sh` (via SSH) |
| OpenWrt | `/tmp/update-openwrt.sh` (via SSH) |
| DD-WRT | `/tmp/update-ddwrt.sh` (via SSH) |
| Proxmox | `~/update-proxmox.sh` (via SSH) |
| ESXi | `~/update-esxi.sh` (via SSH) |

## Logs

| Platform | Log Location |
|---|---|
| macOS | `~/Documents/logs/mac/mac-update.log` |
| Linux (Debian) | `~/logs/debian/debian-update.log` |
| Linux (Arch) | `~/logs/arch/arch-update.log` |
| Linux (RHEL) | `~/logs/rhel/rhel-update.log` |
| Linux (Alpine) | `~/logs/alpine/alpine-update.log` |
| Linux (generic) | `~/logs/linux/linux-update.log` |
| Raspberry Pi | `~/logs/raspios/raspi-update.log` |
| FreeBSD | `~/logs/freebsd/freebsd-update.log` |
| Windows | `%USERPROFILE%\Documents\logs\windows-maintenance\windows-update.log` |
| QNAP | `/share/homes/admin/logs/qnap/qnap-update.log` |
| Synology | `/volume1/homes/admin/logs/synology/synology-update.log` |
| Unraid | `/boot/logs/unraid/unraid-update.log` |
| TrueNAS | `/root/logs/truenas/truenas-update.log` |
| OPNsense | `/root/logs/opnsense/opnsense-update.log` |
| pfSense | `/root/logs/pfsense/pfsense-update.log` |
| OpenWrt | `/tmp/logs/openwrt/openwrt-update.log` (RAM, lost on reboot) |
| DD-WRT | `/tmp/logs/ddwrt/ddwrt-update.log` (RAM, lost on reboot) |
| Proxmox | `/root/logs/proxmox/proxmox-update.log` |
| ESXi | `/scratch/logs/esxi/esxi-update.log` |

All logs append on each run with a timestamped separator. Never overwritten.

## Features

- Auto-detects package manager on generic Linux (apt/dnf/pacman/zypper)
- Auto-detects Raspberry Pi vs standard Linux
- Auto-detects TrueNAS SCALE vs CORE
- Docker container image updates on all NAS/hypervisor platforms
- ZFS pool status on TrueNAS and Proxmox
- Disk SMART health check on all server/NAS platforms
- WireGuard tunnel status on OPNsense
- AUR support on Arch (yay/paru auto-detected)
- Firmware updates via fwupd on Debian/Arch/RHEL
- Config backup on OpenWrt before updates
- Interactive prompts before installing OS/firmware updates
- Never auto-reboots — always asks first
- Gracefully skips missing tools
- Shared utility library in common/utils.sh

## Additional Docs

- macOS app list: docs/HOMEBREW-APPS.md
- Windows setup guide: docs/WINDOWS-SETUP.md

## License

MIT
