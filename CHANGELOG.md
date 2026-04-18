# Changelog

All notable changes to system-update-automation are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [1.4.0] - 2026-04-17

### Added
- `common/check-health.sh` — cross-platform health check (disk, memory, CPU, services, SMART, network)
- `common/notify.sh` — notification support for Slack, Discord, ntfy.sh, Pushover, and email
- `common/summarize-logs.sh` — parse update/health logs and generate 30-day activity report
- `common/inventory.sh` — full system inventory (hardware, OS, packages, services, network, security)
- `common/security-check.sh` — security audit (failed logins, open ports, firewall, SSH config, secrets scan)
- `common/network-check.sh` — homelab network topology checker (ping all known hosts, DNS, latency)
- `windows/cleanup-windows.ps1` — Windows cleanup (temp files, recycle bin, Update cache, browser caches)

---

## [1.3.0] - 2026-04-17

### Added
- Major version upgrade scripts: `upgrade/upgrade-debian.sh`, `upgrade/upgrade-rhel.sh`, `upgrade/upgrade-freebsd.sh`, `upgrade/upgrade-alpine.sh`
- `docs/UPGRADE-GUIDE.md` — comprehensive pre-upgrade checklist, recovery steps, version paths
- Self-update interval check in `update-mac` and `update-windows.ps1` — prompts every 7 days (configurable)
- `self-update.sh` — Mac/Linux self-updater with local change detection and backup
- `windows/self-update.ps1` — Windows self-updater with local change detection and backup
- `CHANGELOG.md` — full version history
- Comprehensive `README.md` with all platforms, install instructions, and usage

### Changed
- `update-mac` — added macOS/Homebrew version checks, self-update interval logic
- `update-windows.ps1` — added self-update interval logic, ARM64 architecture detection

---

## [1.2.0] - 2026-04-17

### Added
- Version checks and error handling to all 19 platform scripts
- `docs/VERSION-REQUIREMENTS.md` — minimum supported versions for all platforms

### Fixed
- FreeBSD: portsnap deprecated in 14+ — now uses git for ports tree
- Raspberry Pi: rpi-eeprom only invoked on Pi 4/5 (model auto-detected)
- QNAP/Synology/Unraid: log directory falls back to /tmp if primary path unavailable

---

## [1.1.0] - 2026-04-17

### Added
- Router scripts: `router/update-openwrt.sh`, `router/update-ddwrt.sh`
- Linux distro-specific scripts: Debian, Arch, RHEL, Alpine
- Universal installer `install.sh` — auto-detects OS
- `common/utils.sh` — shared utility functions
- `docs/WINDOWS-SETUP.md`

### Changed
- Repo renamed from `mac-update-automation` to `system-update-automation`
- Restructured into platform folders

---

## [1.0.0] - 2026-03-27

### Added
- `mac/update-mac` — macOS maintenance (Homebrew, mas, macOS updates)
- `windows/update-windows.ps1` — Windows maintenance (winget, Chocolatey, Windows Update)
  - ARM64 vs AMD64 auto-detection
  - Native COM API for Windows Update (ARM64 compatible)
  - Microsoft Edge pinned in winget on ARM64
- `linux/update-linux.sh` — Generic Linux (apt/dnf/pacman/zypper auto-detected)
- `raspios/update-raspi.sh` — Raspberry Pi OS
- `freebsd/update-freebsd.sh` — FreeBSD
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
| DD-WRT | Logs in /tmp (RAM) — lost on reboot | Mount USB for persistence |
| ESXi | Online depot requires internet access | Often blocked in enterprise |
| CentOS 7 | Uses yum not dnf — not supported | Migrate to Rocky/AlmaLinux |
