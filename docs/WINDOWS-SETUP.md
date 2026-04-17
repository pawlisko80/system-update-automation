# Windows Update Automation

PowerShell script for automated Windows maintenance — winget, Microsoft Store, Chocolatey, and Windows Update in one shot.

## What It Does

| Step | Action |
|---|---|
| winget | Upgrades all winget-managed packages |
| Microsoft Store | Updates all Store apps via winget msstore source |
| Chocolatey | Upgrades all choco packages (if installed) |
| Windows Update | Lists available updates, prompts Y/ENTER to install |

## Prerequisites

### 1. winget (App Installer)
Usually pre-installed on Windows 11. If missing, install from Microsoft Store:
- Search **App Installer** in Microsoft Store

Verify:
```
winget --version
```

### 2. Chocolatey (optional but recommended)
```
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

Verify:
```
choco --version
```

### 3. PSWindowsUpdate module
The script will auto-install this on first run if missing. Or install manually:
```
Install-Module PSWindowsUpdate -Force -Scope CurrentUser
```

## Installation

### Option 1 — Clone from GitHub (recommended)
```
git clone https://github.com/pawlisko80/mac-update-automation.git C:\scripts
```

### Option 2 — Manual download
Download `update-windows.ps1` and place in:
```
C:\scripts\windows-maintenance\update-windows.ps1
```

### Add to PATH (optional — run from anywhere)
```
[Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";C:\scripts\windows-maintenance", "User")
```

### Set PowerShell execution policy
Required to run local scripts:
```
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Usage

### Run as Administrator (required)
Right-click PowerShell → Run as Administrator, then:
```
update-windows
```

Or navigate to the script location:
```
cd C:\scripts\windows-maintenance
.\update-windows.ps1
```

### Create a shortcut for easy access
1. Right-click Desktop → New → Shortcut
2. Target:
```
powershell.exe -ExecutionPolicy Bypass -File "C:\scripts\windows-maintenance\update-windows.ps1"
```
3. Right-click shortcut → Properties → Advanced → check **Run as administrator**

## Logs

All logs saved to:
```
%USERPROFILE%\Documents\logs\windows-maintenance\windows-update.log
```

Each run appends with a timestamped separator — same pattern as the Mac script.

## Notes

- Script **requires Administrator** privileges for Windows Update and some winget operations
- Chocolatey is **optional** — script skips gracefully if not installed
- PSWindowsUpdate is **auto-installed** on first run if missing
- Windows Update install is **interactive** — prompts before installing, never auto-reboots
- Safe to run multiple times — log always appends, never overwrites

## Equivalent Mac Script

See [README.md](README.md) for the macOS equivalent using Homebrew and mas.
