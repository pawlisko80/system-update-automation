# Version Requirements

Minimum supported versions for each platform script.

## Desktop / Workstation

| Platform | Script | Min Version | Notes |
|---|---|---|---|
| macOS | `mac/update-mac` | macOS 12 (Monterey) | Homebrew 3.0+, mas 1.8+ required |
| Windows | `windows/update-windows.ps1` | Windows 10 1903 / Windows 11 | winget requires App Installer from MS Store |

## Linux

| Platform | Script | Min Version | Notes |
|---|---|---|---|
| Debian | `linux/debian/update-debian.sh` | Debian 10 (Buster) | Ubuntu 20.04+, Mint 20+ |
| Arch | `linux/arch/update-arch.sh` | Any current Arch | Rolling release, no version constraint |
| RHEL/Fedora | `linux/rhel/update-rhel.sh` | RHEL 8 / Fedora 33 | CentOS 7 NOT supported (yum only) |
| Alpine | `linux/alpine/update-alpine.sh` | Alpine 3.12+ | |
| Generic | `linux/update-linux.sh` | Varies by PM | apt/dnf/pacman/zypper auto-detected |
| Raspberry Pi | `raspios/update-raspi.sh` | Pi OS Buster (10) | rpi-eeprom only on Pi 4/5 |

## BSD

| Platform | Script | Min Version | Notes |
|---|---|---|---|
| FreeBSD | `freebsd/update-freebsd.sh` | FreeBSD 12.0 | portsnap deprecated in 14+ (git used instead) |

## NAS

| Platform | Script | Min Version | Notes |
|---|---|---|---|
| QNAP | `nas/update-qnap.sh` | QTS 4.5 | bash required (not sh) |
| Synology | `nas/update-synology.sh` | DSM 6.2 | |
| Unraid | `nas/update-unraid.sh` | Unraid 6.9 | |
| TrueNAS | `nas/update-truenas.sh` | SCALE 22.x / CORE 13 | Auto-detects SCALE vs CORE |

## Firewall

| Platform | Script | Min Version | Notes |
|---|---|---|---|
| OPNsense | `firewall/update-opnsense.sh` | OPNsense 21.1 | |
| pfSense | `firewall/update-pfsense.sh` | pfSense 2.5 | |

## Router

| Platform | Script | Min Version | Notes |
|---|---|---|---|
| OpenWrt | `router/update-openwrt.sh` | OpenWrt 19.07 | |
| DD-WRT | `router/update-ddwrt.sh` | Any with BusyBox | RAM filesystem — logs lost on reboot |

## Hypervisor

| Platform | Script | Min Version | Notes |
|---|---|---|---|
| Proxmox VE | `hypervisor/update-proxmox.sh` | PVE 7.0 | pveupgrade syntax changed in v7 |
| ESXi | `hypervisor/update-esxi.sh` | ESXi 6.7 | |

## Windows Architecture Notes

| Architecture | Windows Update | Edge Updates | winget |
|---|---|---|---|
| AMD64/x86 | PSWindowsUpdate module | winget handles | Full support |
| ARM64 | Native COM API | Microsoft AutoUpdate (pinned in winget) | Mostly works |

## Known Limitations

- **CentOS 7**: Uses yum not dnf — use manual `yum update` instead
- **FreeBSD 14+**: portsnap deprecated — ports tree uses git
- **QNAP QTS < 4.5**: bash may not be available — use sh
- **Proxmox VE 6**: pveupgrade syntax differs — use apt upgrade manually
- **DD-WRT**: Logs stored in RAM (/tmp) — lost on reboot. Mount USB for persistence
- **ESXi**: Online depot update requires ESXi internet access — often blocked in enterprise
- **ARM64 Windows**: PSWindowsUpdate broken — native COM API used instead
- **macOS < 12**: Homebrew 3.0+ requires macOS 12+

## Optional Dependencies

| Tool | Platform | Install | Purpose |
|---|---|---|---|
| smartmontools | macOS / Linux | `brew install smartmontools` / `apt install smartmontools` | Disk SMART health checks in check-health.sh |
| mas | macOS | `brew install mas` | App Store updates in update-mac |
