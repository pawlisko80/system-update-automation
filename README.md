# system-update-automation

Cross-platform system maintenance and update automation scripts.
Covers desktops, servers, NAS devices, firewalls, and hypervisors.

## Supported Platforms

| Category | Platform | Script | Package Managers / Sources |
|---|---|---|---|
| Desktop | macOS | `mac/update-mac` | Homebrew, mas (App Store) |
| Desktop | Windows | `windows/update-windows.ps1` | winget, Microsoft Store, Chocolatey |
| OS | Linux | `linux/update-linux.sh` | apt, dnf, pacman, zypper (auto-detected) |
| OS | Raspberry Pi OS | `raspios/update-raspi.sh` | apt, rpi-update, rpi-eeprom |
| OS | FreeBSD | `freebsd/update-freebsd.sh` | freebsd-update, pkg, ports |
| NAS | QNAP | `nas/update-qnap.sh` | Entware (opkg), Docker |
| NAS | Synology | `nas/update-synology.sh` | Entware (opkg/ipkg), Docker |
| NAS | Unraid | `nas/update-unraid.sh` | Docker, plugins, array check |
| NAS | TrueNAS SCALE/CORE | `nas/update-truenas.sh` | Apps/jails, Docker, ZFS |
| Firewall | OPNsense | `firewall/update-opnsense.sh` | pkg, firmware, plugins, WireGuard |
| Firewall | pfSense | `firewall/update-pfsense.sh` | pkg, packages |
| Hypervisor | Proxmox VE | `hypervisor/update-proxmox.sh` | apt, pveupgrade, LXC templates |
| Hypervisor | ESXi | `hypervisor/update-esxi.sh` | esxcli, VIBs |

## Repository Structure

    system-update-automation/
    ├── mac/
    │   └── update-mac
    ├── windows/
    │   └── update-windows.ps1
    ├── linux/
    │   └── update-linux.sh
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

### Linux

    git clone https://github.com/pawlisko80/system-update-automation.git ~/scripts
    mkdir -p ~/logs/linux
    chmod +x ~/scripts/linux/update-linux.sh
    echo 'export PATH="$HOME/scripts/linux:$HOME/scripts/common:$PATH"' >> ~/.bashrc
    source ~/.bashrc

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

SSH into your NAS, then:

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

SSH into your firewall, then:

    # OPNsense
    curl -fsSL https://raw.githubusercontent.com/pawlisko80/system-update-automation/main/firewall/update-opnsense.sh -o ~/update-opnsense.sh
    chmod +x ~/update-opnsense.sh && ~/update-opnsense.sh

    # pfSense
    curl -fsSL https://raw.githubusercontent.com/pawlisko80/system-update-automation/main/firewall/update-pfsense.sh -o ~/update-pfsense.sh
    chmod +x ~/update-pfsense.sh && ~/update-pfsense.sh

### Hypervisors (Proxmox / ESXi)

SSH into your hypervisor, then:

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
| Linux | `update-linux` |
| Raspberry Pi | `update-raspi` |
| FreeBSD | `update-freebsd` |
| Windows | `update-windows` (as Administrator) |
| QNAP | `~/update-qnap.sh` (via SSH) |
| Synology | `~/update-synology.sh` (via SSH) |
| Unraid | `~/update-unraid.sh` (via SSH) |
| TrueNAS | `~/update-truenas.sh` (via SSH) |
| OPNsense | `~/update-opnsense.sh` (via SSH) |
| pfSense | `~/update-pfsense.sh` (via SSH) |
| Proxmox | `~/update-proxmox.sh` (via SSH) |
| ESXi | `~/update-esxi.sh` (via SSH) |

## Logs

| Platform | Log Location |
|---|---|
| macOS | `~/Documents/logs/mac/mac-update.log` |
| Linux | `~/logs/linux/linux-update.log` |
| Raspberry Pi | `~/logs/raspios/raspi-update.log` |
| FreeBSD | `~/logs/freebsd/freebsd-update.log` |
| Windows | `%USERPROFILE%\Documents\logs\windows-maintenance\windows-update.log` |
| QNAP | `/share/homes/admin/logs/qnap/qnap-update.log` |
| Synology | `/volume1/homes/admin/logs/synology/synology-update.log` |
| Unraid | `/boot/logs/unraid/unraid-update.log` |
| TrueNAS | `/root/logs/truenas/truenas-update.log` |
| OPNsense | `/root/logs/opnsense/opnsense-update.log` |
| pfSense | `/root/logs/pfsense/pfsense-update.log` |
| Proxmox | `/root/logs/proxmox/proxmox-update.log` |
| ESXi | `/scratch/logs/esxi/esxi-update.log` |

All logs append on each run with a timestamped separator. Never overwritten.

## Features

- Auto-detects package manager on Linux (apt/dnf/pacman/zypper)
- Auto-detects Raspberry Pi vs standard Linux
- Auto-detects TrueNAS SCALE vs CORE
- Docker container image updates on all NAS/hypervisor platforms
- ZFS pool status on TrueNAS and Proxmox
- Disk SMART health check on all server/NAS platforms
- WireGuard tunnel status on OPNsense
- Interactive prompts before installing OS/firmware updates
- Never auto-reboots — always asks first
- Gracefully skips missing tools
- Shared utility library in common/utils.sh

## Additional Docs

- macOS app list: docs/HOMEBREW-APPS.md
- Windows setup guide: docs/WINDOWS-SETUP.md

## License

MIT
