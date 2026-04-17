# system-update-automation

Cross-platform system maintenance and update automation scripts.
Tested on macOS 26 Tahoe (Apple Silicon), Windows 11, Raspberry Pi OS, Ubuntu, and FreeBSD.

## Supported Platforms

| Platform | Script | Package Managers |
|---|---|---|
| macOS | `mac/update-mac` | Homebrew, mas (App Store) |
| Windows | `windows/update-windows.ps1` | winget, Microsoft Store, Chocolatey |
| Linux | `linux/update-linux.sh` | apt, dnf, pacman, zypper (auto-detected) |
| Raspberry Pi OS | `raspios/update-raspi.sh` | apt, rpi-update, rpi-eeprom |
| FreeBSD | `freebsd/update-freebsd.sh` | freebsd-update, pkg, ports |

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
    ├── common/
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
    which update-mac

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

## Usage

From anywhere in terminal:

| Platform | Command |
|---|---|
| macOS | `update-mac` |
| Linux | `update-linux` |
| Raspberry Pi | `update-raspi` |
| FreeBSD | `update-freebsd` |
| Windows | `update-windows` (as Administrator) |

## Logs

| Platform | Log Location |
|---|---|
| macOS | `~/Documents/logs/mac/mac-update.log` |
| Linux | `~/logs/linux/linux-update.log` |
| Raspberry Pi | `~/logs/raspios/raspi-update.log` |
| FreeBSD | `~/logs/freebsd/freebsd-update.log` |
| Windows | `%USERPROFILE%\Documents\logs\windows-maintenance\windows-update.log` |

All logs append on each run with a timestamped separator. Never overwritten.

## Features

- Auto-detects package manager on Linux (apt/dnf/pacman/zypper)
- Auto-detects Raspberry Pi vs standard Linux
- Interactive prompts before installing OS/firmware updates
- Never auto-reboots — always asks first
- Gracefully skips missing tools (snap, flatpak, chocolatey, ports)
- Consistent log format across all platforms

## Additional Docs

- macOS app list: docs/HOMEBREW-APPS.md
- Windows setup guide: docs/WINDOWS-SETUP.md

## License

MIT
