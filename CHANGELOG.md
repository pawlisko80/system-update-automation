# Changelog

All notable changes to system-update-automation are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [1.6.0] - 2026-04-18

### Added
- `common/hosts.conf` - centralized network host configuration file
  - Single file shared by both Mac/Linux and Windows network check scripts
  - Format: `IP|Name|Description` with comment support
  - Add a device once, both platforms pick it up on next git pull
- Interactive maintenance menus for all platforms
  - `mac/menu` - macOS menu (type `menu` from anywhere)
  - `linux/menu` - Linux menu (auto-detects distro for update script)
  - `raspios/menu` - Raspberry Pi menu
  - `freebsd/menu` - FreeBSD menu
  - `windows/menu.ps1` - Windows PowerShell menu
  - All menus: options 1-8 plus 9/q to quit
- Windows-native PowerShell scripts (no Git Bash required)
  - `windows/check-health.ps1` - disk, memory, CPU, services, Windows Update, network
  - `windows/security-check.ps1` - failed logins, firewall, open ports, updates, admin accounts, secrets scan
  - `windows/inventory.ps1` - hardware, OS, packages, services, network, logins
  - `windows/network-check.ps1` - reads from hosts.conf, pings all homelab devices

### Changed
- `common/network-check.sh` - now reads hosts from `common/hosts.conf` instead of hardcoded array
- `windows/network-check.ps1` - now reads hosts from `common/hosts.conf` instead of hardcoded array
- All Windows PS1 scripts - replaced em-dashes and non-ASCII characters with ASCII equivalents to prevent encoding errors on git pull
- `windows/menu.ps1` - fixed header padding formula to work dynamically for any hostname length
- `common/check-health.sh` - whitelisted harmless stopped services (edgeupdate, MapsBroker, sppsvc)

### Fixed
- Windows PS1 scripts encoding corruption (em-dashes causing parse errors after git pull)
- Windows menu border misalignment on info line
- Network check wrong IPs (switch .3, NAS .30)
- Inventory `2>/dev/null` bash syntax replaced with PowerShell `2>$null`
- Inventory login filter now excludes SYSTEM accounts, shows only real user logins

---

## [1.5.2] - 2026-04-18

### Fixed
- Windows menu header padding formula now dynamic (was hardcoded, broke on different hostnames)
- Windows PS1 scripts encoding issues causing parse errors

---

## [1.5.1] - 2026-04-18

### Fixed
- Windows menu: use DNS hostname to show full computer name (bypasses 15-char NetBIOS limit)
- Windows menu: replaced emojis and box-drawing characters with ASCII for encoding compatibility

---

## [1.5.0] - 2026-04-18

### Added
- Interactive maintenance menus for all platforms (mac, linux, raspios, freebsd, windows)
- Both `9` and `q` work as quit on all menus

---

## [1.4.0] - 2026-04-17

### Added
- `common/check-health.sh` - cross-platform health check (disk, memory, CPU, services, SMART, network)
- `common/notify.sh` - notification support for Slack, Discord, ntfy.sh, Pushover, email
- `common/summarize-logs.sh` - parse update/health logs and generate 30-day activity report
- `common/inventory.sh` - full system inventory (hardware, OS, packages, services, network, security)
- `common/security-check.sh` - security audit (failed logins, open ports, firewall, SSH config, secrets scan)
- `common/network-check.sh` - homelab network topology checker (ping all known hosts, DNS, latency)
- `windows/cleanup-windows.ps1` - Windows cleanup (temp files, recycle bin, Update cache, browser caches)

---

## [1.3.0] - 2026-04-17

### Added
- Major version upgrade scripts: `upgrade/upgrade-debian.sh`, `upgrade/upgrade-rhel.sh`, `upgrade/upgrade-freebsd.sh`, `upgrade/upgrade-alpine.sh`
- `docs/UPGRADE-GUIDE.md` - comprehensive pre-upgrade checklist, recovery steps, version paths
- Self-update interval check in `update-mac` and `update-windows.ps1` - prompts every 7 days (configurable)
- `self-update.sh` - Mac/Linux self-updater with local change detection and backup
- `windows/self-update.ps1` - Windows self-updater with local change detection and backup
- `CHANGELOG.md` - full version history
- Comprehensive `README.md`

---

## [1.2.0] - 2026-04-17

### Added
- Version checks and error handling to all 19 platform scripts
- `docs/VERSION-REQUIREMENTS.md` - minimum supported versions for all platforms

### Fixed
- FreeBSD: portsnap deprecated in 14+ - now uses git for ports tree
- Raspberry Pi: rpi-eeprom only invoked on Pi 4/5 (model auto-detected)
- QNAP/Synology/Unraid: log directory falls back to /tmp if primary path unavailable

---

## [1.1.0] - 2026-04-17

### Added
- Router scripts: OpenWrt, DD-WRT
- Linux distro-specific scripts: Debian, Arch, RHEL, Alpine
- Universal installer `install.sh`
- `common/utils.sh` - shared utility functions
- `docs/WINDOWS-SETUP.md`

### Changed
- Repo renamed from `mac-update-automation` to `system-update-automation`
- Restructured into platform folders

---

## [1.0.0] - 2026-03-27

### Added
- `mac/update-mac` - macOS maintenance (Homebrew, mas, macOS updates)
- `windows/update-windows.ps1` - Windows maintenance (winget, Chocolatey, Windows Update)
  - ARM64 vs AMD64 auto-detection
  - Native COM API for Windows Update (ARM64 compatible)
  - Microsoft Edge pinned in winget on ARM64
- `linux/update-linux.sh` - Generic Linux (apt/dnf/pacman/zypper auto-detected)
- `raspios/update-raspi.sh` - Raspberry Pi OS
- `freebsd/update-freebsd.sh` - FreeBSD
- NAS scripts: QNAP, Synology, Unraid, TrueNAS
- Firewall scripts: OPNsense, pfSense
- Hypervisor scripts: Proxmox VE, ESXi
- `docs/HOMEBREW-APPS.md`

---

## Known Issues / Limitations

| Platform | Issue | Status |
|---|---|---|
| MakeMKV | Homebrew cask deprecated Sept 2026 | Manual update after deprecation |
| VMware Fusion | Homebrew cask disabled (Broadcom login) | Manual download from broadcom.com |
| Samsung Magician | installer manual cask | Open app to check for updates |
| DD-WRT | Logs in /tmp (RAM) - lost on reboot | Mount USB for persistence |
| ESXi | Online depot requires internet access | Often blocked in enterprise |
| CentOS 7 | Uses yum not dnf - not supported | Migrate to Rocky/AlmaLinux |
