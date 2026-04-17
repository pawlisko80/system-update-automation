# Major Version Upgrade Guide

## ⚠️ IMPORTANT — Read Before Running Any Upgrade Script

Major version upgrades are **irreversible without a full restore**.
Always back up and test in a non-production environment first.

---

## Pre-Upgrade Checklist (All Platforms)

- [ ] Full system backup or VM snapshot taken
- [ ] All current updates applied (`update-*` scripts run first)
- [ ] At least 5GB free disk space
- [ ] Scheduled during a maintenance window
- [ ] Know how to restore from backup if needed
- [ ] Test on non-critical system first

---

## Platform-Specific Notes

### Debian / Ubuntu (`upgrade-debian.sh`)
- Supports: Debian 10→11→12→13, Ubuntu LTS→LTS
- **One major version at a time** — do not skip versions
- Ubuntu uses `do-release-upgrade` automatically
- Debian manually updates `/etc/apt/sources.list`
- Expect 30-60 minutes downtime
- Reboot required after upgrade

### RHEL / Fedora / Rocky / AlmaLinux (`upgrade-rhel.sh`)
- Fedora: uses `dnf system-upgrade` plugin
- RHEL/Rocky/Alma: uses `leapp` upgrade tool
- **CentOS 7 is EOL** — migrate to Rocky or AlmaLinux instead
- RHEL requires valid subscription
- Expect 30-90 minutes downtime
- Reboot required after upgrade

### FreeBSD (`upgrade-freebsd.sh`)
- Uses `freebsd-update upgrade`
- Only supports RELEASE builds (not CURRENT/STABLE)
- **Two-reboot process** — must run `freebsd-update install` twice
- After upgrade, run `pkg upgrade` to update all packages
- portsnap deprecated in FreeBSD 14+ (use git)
- Expect 30-60 minutes downtime

### Alpine Linux (`upgrade-alpine.sh`)
- Updates `/etc/apk/repositories` to new branch
- Runs `apk upgrade --available`
- Simple but verify target version exists first
- Edge users: already rolling, no major upgrade needed
- Expect 5-15 minutes downtime

---

## Platforms — GUI/Manual Upgrade Only

These platforms do not have reliable CLI upgrade paths.
Use their respective web interfaces:

| Platform | How to Upgrade |
|---|---|
| macOS | System Settings → General → Software Update |
| Windows | Settings → Windows Update → Check for Updates |
| OPNsense | System → Firmware → Updates |
| pfSense | System → Update → System Update |
| QNAP | Control Panel → System → Firmware Update |
| Synology | Control Panel → Update & Restore → DSM Update |
| Unraid | Tools → Update OS |
| TrueNAS | System → Update |
| Proxmox | Node → Updates → Upgrade (in web UI) |

---

## Recovery Steps (If Upgrade Fails)

### Debian/Ubuntu — restore sources
```bash
sudo cp /root/pre-upgrade-backup-*/sources.list /etc/apt/sources.list
sudo apt update
```

### Alpine — restore repos
```bash
cp /etc/apk/repositories.bak-YYYYMMDD /etc/apk/repositories
apk update
```

### FreeBSD — rollback
```bash
freebsd-update rollback
reboot
```

### All platforms — restore from backup
If in a VM: revert to pre-upgrade snapshot.

---

## Version Upgrade Paths

### Debian
```
10 (Buster) → 11 (Bullseye) → 12 (Bookworm) → 13 (Trixie)
```

### Ubuntu LTS
```
20.04 (Focal) → 22.04 (Jammy) → 24.04 (Noble)
```

### FreeBSD
```
12.x → 13.x → 14.x
```

### Alpine
```
3.17 → 3.18 → 3.19 → 3.20 → 3.21
```

### Fedora
```
N → N+1 (yearly releases)
```

### RHEL/Rocky/AlmaLinux
```
8.x → 9.x (via leapp)
```
