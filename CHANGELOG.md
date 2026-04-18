# Changelog

All notable changes to system-update-automation are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [1.3.0] - 2026-04-17

### Added
- Major version upgrade scripts: `upgrade/upgrade-debian.sh`, `upgrade/upgrade-rhel.sh`, `upgrade/upgrade-freebsd.sh`, `upgrade/upgrade-alpine.sh`
- `docs/UPGRADE-GUIDE.md` — comprehensive pre-upgrade checklist, recovery steps, version paths for all platforms
- Self-update interval check in `update-mac` and `update-windows.ps1` — prompts every 7 days (configurable) to pull latest scripts from GitHub
- `self-update.sh` — Mac/Linux self-updater with local change detection and backup
- `windows/self-update.ps1` — Windows self-updater with local change detection and backup

### Changed
- `update-mac` — added macOS/Homebrew version checks, requirement validation, self-update interval logic
- `update-windows.ps1` — added self-update interval logic, ARM64 architecture detection

---

## [1.2.0] - 2026-04-17

### Added
- Version checks and error handling to all platform scripts
- `docs/VERSION-REQUIREMENTS.md` — minimum supported versions for all 19 platforms
- Version checks added to: `update-debian.sh`, `update-rhel.sh`, `update-freebsd.sh`, `update-raspi.sh`, `update-proxmox.sh`, `update-opnsense.sh`, `update-qnap.sh`, `update-synology.sh`, `update-unraid.sh`, `update-truenas.sh`, `update-pfsense.sh`, `update-esxi.sh`, `update-openwrt.sh`, `update-ddwrt.sh`, `update-arch.sh`, `update-alpine.sh`, `update-linux.sh`

### Fixed
- FreeBSD: portsnap deprecated in FreeBSD 14+ — now uses git for ports tree
- Raspberry Pi: rpi-eeprom only invoked on Pi 4/5 (model auto-detected)
- QNAP: log directory falls back to /tmp if /share/homes/admin unavailable
- Synology: log directory falls back to /tmp if /volume1/homes/admin unavailable
- Unraid: log directory falls back to /tmp if /boot/logs unavailable

---

## [1.1.0] - 2026-04-17

### Added
- Router scripts: `router/update-openwrt.sh`, `router/update-ddwrt.sh`
- Linux distro-specific scripts: `linux/debian/update-debian.sh`, `linux/arch/update-arch.sh`, `linux/rhel/update-rhel.sh`, `linux/alpine/update-alpine.sh`
- Universal installer `install.sh` — auto-detects OS and sets up correct script + PATH
- `common/utils.sh` — shared utility functions (logging, Docker helpers, SMART health, reboot check)
- `docs/WINDOWS-SETUP.md` — Windows prerequisites and setup guide

### Changed
- Repo renamed from `mac-update-automation` to `system-update-automation`
- Restructured folders: `mac/`, `windows/`, `linux/`, `nas/`, `firewall/`, `router/`, `hypervisor/`, `common/`, `docs/`

---

## [1.0.0] - 2026-03-27

### Added
- `mac/update-mac` — macOS maintenance script (Homebrew, mas, macOS updates, manual reminders)
- `windows/update-windows.ps1` — Windows maintenance script
  - winget package upgrades
  - Microsoft Store updates
  - Chocolatey upgrades
  - Windows Update via native COM API (ARM64 compatible)
  - ARM64 vs AMD64/x86 auto-detection
  - Microsoft Edge pinned in winget on ARM64 (installer technology mismatch)
- `linux/update-linux.sh` — Generic Linux script (apt/dnf/pacman/zypper auto-detected)
- `raspios/update-raspi.sh` — Raspberry Pi OS (apt, rpi-update, rpi-eeprom)
- `freebsd/update-freebsd.sh` — FreeBSD (freebsd-update, pkg, ports)
- NAS scripts: `nas/update-qnap.sh`, `nas/update-synology.sh`, `nas/update-unraid.sh`, `nas/update-truenas.sh`
- Firewall scripts: `firewall/update-opnsense.sh`, `firewall/update-pfsense.sh`
- Hypervisor scripts: `hypervisor/update-proxmox.sh`, `hypervisor/update-esxi.sh`
- `docs/HOMEBREW-APPS.md` — complete list of Homebrew-managed apps
- `README.md` — full documentation

### Notes
- Windows ARM64: PSWindowsUpdate broken — replaced with native COM API
- Windows ARM64: Microsoft Edge excluded from winget (uses Microsoft AutoUpdate instead)
- macOS: fuse-t used instead of macFUSE for VeraCrypt on Apple Silicon
- macOS: All apps migrated from DMG installs to Homebrew casks

---

## Known Issues / Limitations

| Platform | Issue | Status |
|---|---|---|
| MakeMKV | Homebrew cask deprecated Sept 2026 (Gatekeeper) | Manual update after deprecation |
| VMware Fusion | Homebrew cask disabled (requires Broadcom login) | Manual download from broadcom.com |
| Samsung Magician | `installer manual` cask — brew cannot auto-upgrade | Open app to check for updates |
| DD-WRT | Logs in /tmp (RAM) — lost on reboot | Mount USB for persistence |
| ESXi | Online depot requires ESXi internet access | Often blocked in enterprise |
| CentOS 7 | Uses yum not dnf — not supported | Migrate to Rocky/AlmaLinux |
