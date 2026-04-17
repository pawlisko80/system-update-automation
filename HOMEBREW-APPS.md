# Homebrew-Managed Apps

Complete list of applications managed via Homebrew on this Mac.
All can be updated automatically via the `update-mac` script.

## Casks (GUI Apps)

| App | Cask | Notes |
|---|---|---|
| AppCleaner | `appcleaner` | App uninstaller |
| balenaEtcher | `balenaetcher` | USB image flasher |
| Box Drive | `box-drive` | Box cloud storage |
| ChatGPT | `chatgpt` | OpenAI desktop app |
| Claude | `claude` | Anthropic desktop app |
| Dropbox | `dropbox` | Cloud storage |
| freac | `freac` | Audio converter |
| fuse-t | `fuse-t` | FUSE for Apple Silicon (VeraCrypt dependency) |
| Google Drive | `google-drive` | Google cloud storage |
| HandBrake | `handbrake-app` | Video transcoder |
| HDHomeRun | `hdhomerun` | Network TV tuner |
| IINA | `iina` | Media player |
| MakeMKV | `makemkv` | Blu-ray/DVD ripper (deprecated, manual after Sept 2026) |
| Microsoft Edge | `microsoft-edge` | Browser |
| OneDrive | `onedrive` | Microsoft cloud storage |
| Plex | `plex` | Media server client |
| Proton Drive | `proton-drive` | Proton cloud storage |
| Proton Mail | `proton-mail` | Encrypted email |
| Proton Pass | `proton-pass` | Password manager |
| ProtonVPN | `protonvpn` | VPN client |
| RealVNC Connect | `realvnc-connect` | Remote desktop |
| Samsung Magician | `samsung-magician` | SSD management (manual installer) |
| VeraCrypt | `veracrypt-fuse-t` | Disk encryption (Apple Silicon build) |
| WhatsApp | `whatsapp` | Messaging |

## Formulae (CLI Tools)

| Tool | Formula | Notes |
|---|---|---|
| GitHub CLI | `gh` | GitHub command line tool |
| mas | `mas` | Mac App Store CLI |

## App Store Apps (managed via mas)

| App | App Store ID |
|---|---|
| GarageBand | 682658836 |
| iMovie | 408981434 |
| Keynote | 409183694 |
| Microsoft To Do | 1274495053 |
| Numbers | 409203825 |
| Pages | 409201541 |
| Perplexity | 6714467650 |
| Proton Pass for Safari | 6502835663 |
| Windows App | 1295203466 |
| WireGuard | 1451685025 |
| Yubico Authenticator | 1497506650 |

## Apps NOT Managed by Homebrew

| App | Reason | Update Method |
|---|---|---|
| VMware Fusion | Requires Broadcom account to download | Manual from broadcom.com |
| Microsoft Office | Best managed by Microsoft AutoUpdate | AutoUpdate or App Store |
| OVPN | No Homebrew cask available | Update from within app |

## Migrating from DMG to Homebrew

To migrate a manually installed app to Homebrew:

    # Remove old version
    sudo rm -rf /Applications/AppName.app

    # Install via Homebrew
    brew install --cask cask-name

From that point on, update-mac will keep it current automatically.

## Finding Available Casks

    # Search for a specific app
    brew search appname

    # Check if installed app is already managed
    brew list --cask | grep appname

## Useful Homebrew Commands

    # List all installed casks and formulae
    brew list

    # Check for outdated packages
    brew outdated

    # Get info on a specific cask
    brew info --cask cask-name

    # Remove a cask
    brew uninstall --cask cask-name
