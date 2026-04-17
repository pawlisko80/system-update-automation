# =============================================================
# self-update.ps1 — Auto-update scripts from GitHub (Windows)
# Updates all scripts in C:\scripts from the remote repo
# Safe: backs up local changes before pulling
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

$ScriptsDir = "C:\scripts"
$RepoUrl    = "https://github.com/pawlisko80/system-update-automation.git"
$BackupDir  = "$env:USERPROFILE\scripts-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

function Write-Ok   { param($m) Write-Host "OK  $m" -ForegroundColor Green }
function Write-Warn { param($m) Write-Host "WRN $m" -ForegroundColor Yellow }
function Write-Err  { param($m) Write-Host "ERR $m" -ForegroundColor Red }

Write-Host "============================================================"
Write-Host "  system-update-automation self-updater (Windows)"
Write-Host "============================================================"
Write-Host ""

# Check git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Err "git not found. Install with: winget install --id Git.Git"
    exit 1
}

# Check scripts directory
if (-not (Test-Path $ScriptsDir)) {
    Write-Err "Scripts directory not found: $ScriptsDir"
    Write-Host "Clone the repo first:"
    Write-Host "  git clone $RepoUrl $ScriptsDir"
    exit 1
}

# Check it's a git repo
if (-not (Test-Path "$ScriptsDir\.git")) {
    Write-Err "$ScriptsDir is not a git repository."
    Write-Host "Clone the repo first:"
    Write-Host "  git clone $RepoUrl $ScriptsDir"
    exit 1
}

Set-Location $ScriptsDir

# Check for local changes
$LocalChanges = git status --porcelain 2>$null
if ($LocalChanges) {
    Write-Warn "Local changes detected:"
    git status --short
    Write-Host ""
    $reply = Read-Host "Back up local changes and continue? (y/N)"
    if ($reply -match '^[Yy]$') {
        Write-Host "Backing up to $BackupDir..."
        Copy-Item -Path $ScriptsDir -Destination $BackupDir -Recurse
        Write-Ok "Backup created at $BackupDir"
    } else {
        Write-Host "Aborting. No changes made."
        exit 0
    }
}

# Fetch and check for updates
Write-Host ""
Write-Host "Checking for updates..."
git fetch origin 2>$null

$Local  = git rev-parse HEAD 2>$null
$Remote = git rev-parse origin/main 2>$null

if ($Local -eq $Remote) {
    Write-Ok "Already up to date. No updates available."
    Write-Host ""
    Write-Host "Current version: $(git log -1 --format='%h %s (%cr)' 2>$null)"
    Read-Host "Press ENTER to close"
    exit 0
}

# Show what will change
Write-Host ""
Write-Host "Updates available:"
git log HEAD..origin/main --oneline 2>$null
Write-Host ""

$reply = Read-Host "Apply updates? (y/N)"
if ($reply -notmatch '^[Yy]$') {
    Write-Host "Aborting. No changes made."
    exit 0
}

# Pull updates
Write-Host ""
Write-Host "Pulling updates..."
git pull --rebase origin main 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Err "Update failed. Check git output above."
    if (Test-Path $BackupDir) {
        Write-Host "Your backup is at: $BackupDir"
    }
    exit 1
}

Write-Host ""
Write-Ok "Update complete!"
Write-Host ""
Write-Host "Latest changes:"
git log -5 --oneline 2>$null
Write-Host ""
Write-Host "============================================================"
Read-Host "Press ENTER to close"
