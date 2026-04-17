# mac-update-automation

Mac maintenance and update automation scripts for macOS (tested on macOS 26 Tahoe, Apple Silicon).

## Repository Structure

    ~/scripts/
    ├── mac-maintenance/
    │   └── update-mac          # Main update script
    ├── homelab/                # Future homelab automation scripts
    └── README.md

## Logs

All logs are stored in:

    ~/Documents/logs/mac-maintenance/mac-update.log

Each run appends to the same file with a timestamped separator for easy review.

## Prerequisites

### 1. Homebrew

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

After install on Apple Silicon, add to PATH:

    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"

### 2. mas (Mac App Store CLI)

    brew install mas

### 3. Xcode Command Line Tools

    xcode-select --install

## Installation

    git clone https://github.com/pawlisko80/mac-update-automation.git ~/scripts
    mkdir -p ~/Documents/logs/mac-maintenance
    chmod +x ~/scripts/mac-maintenance/update-mac
    echo 'export PATH="$HOME/scripts/mac-maintenance:$HOME/scripts/homelab:$PATH"' >> ~/.zprofile
    source ~/.zprofile
    which update-mac

## Usage

From anywhere in Terminal:

    update-mac

Or double-click `update-mac` in Finder and Open With Terminal.

## What It Does

| Step | Action |
|---|---|
| Homebrew update | Refreshes package index |
| Homebrew upgrade | Upgrades all formulae and casks including auto-updating ones (--greedy) |
| App Store | Updates all Mac App Store apps via mas |
| Cleanup | Removes old Homebrew versions and cached downloads |
| macOS check | Lists available macOS/system updates |
| Optional install | Prompts Y/RETURN to install macOS updates immediately |

## Notes

- **Samsung Magician** will always show `installer manual` warning — update manually within the app
- **sudo** is required for macOS software updates — you will be prompted when installing system updates
- Script is safe to run multiple times — appends to log, never overwrites

## Recommended Apps to Manage via Homebrew

See [HOMEBREW-APPS.md](HOMEBREW-APPS.md) for the full list of apps migrated from DMG to Homebrew management.

## License

MIT
