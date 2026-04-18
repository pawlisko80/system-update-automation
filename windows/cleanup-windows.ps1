#Requires -RunAsAdministrator
# =============================================================
# cleanup-windows.ps1 — Windows cleanup script
# Covers: temp files, recycle bin, Windows Update cache,
#         browser caches, Event Log, prefetch
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$LogDir  = "$env:USERPROFILE\Documents\logs\windows-maintenance"
$LogFile = "$LogDir\windows-cleanup-$(Get-Date -Format 'yyyyMMdd').log"

if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] $Message"
    Write-Host $line
    Add-Content -Path $LogFile -Value $line
}

function Write-Separator {
    $line = "=" * 60
    Write-Host $line
    Add-Content -Path $LogFile -Value $line
}

function Get-FolderSize {
    param([string]$Path)
    if (Test-Path $Path) {
        $size = (Get-ChildItem $Path -Recurse -Force -ErrorAction SilentlyContinue |
            Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
        return [math]::Round($size / 1MB, 1)
    }
    return 0
}

function Remove-FolderContents {
    param([string]$Path, [string]$Description)
    if (Test-Path $Path) {
        $sizeBefore = Get-FolderSize $Path
        try {
            Remove-Item "$Path\*" -Recurse -Force -ErrorAction SilentlyContinue
            $sizeAfter = Get-FolderSize $Path
            $freed = $sizeBefore - $sizeAfter
            Write-Log "Cleaned $Description — freed ${freed}MB"
        } catch {
            Write-Log "Partial clean of $Description (some files in use)"
        }
    } else {
        Write-Log "Skipping $Description (path not found)"
    }
}

$TotalFreed = 0

Write-Separator
Write-Log "Windows cleanup started - $(Get-Date)"
Write-Separator

# =============================================================
# Temp folders
# =============================================================
Write-Log ""
Write-Log "Cleaning temp folders..."

$before = (Get-PSDrive C).Free / 1MB

Remove-FolderContents "$env:TEMP" "User temp folder"
Remove-FolderContents "C:\Windows\Temp" "Windows temp folder"
Remove-FolderContents "$env:LOCALAPPDATA\Temp" "Local app temp"

# =============================================================
# Recycle Bin
# =============================================================
Write-Log ""
Write-Log "Emptying Recycle Bin..."
try {
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Write-Log "Recycle Bin emptied."
} catch {
    Write-Log "Could not empty Recycle Bin: $_"
}

# =============================================================
# Windows Update cache
# =============================================================
Write-Log ""
Write-Log "Cleaning Windows Update cache..."
try {
    Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
    Stop-Service -Name bits -Force -ErrorAction SilentlyContinue
    Remove-FolderContents "C:\Windows\SoftwareDistribution\Download" "Windows Update download cache"
    Start-Service -Name wuauserv -ErrorAction SilentlyContinue
    Start-Service -Name bits -ErrorAction SilentlyContinue
    Write-Log "Windows Update services restarted."
} catch {
    Write-Log "Could not clean Windows Update cache: $_"
}

# =============================================================
# Prefetch
# =============================================================
Write-Log ""
Write-Log "Cleaning Prefetch..."
Remove-FolderContents "C:\Windows\Prefetch" "Prefetch"

# =============================================================
# Browser caches
# =============================================================
Write-Log ""
Write-Log "Cleaning browser caches..."

# Edge
$EdgeCache = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
Remove-FolderContents $EdgeCache "Microsoft Edge cache"

# Chrome
$ChromeCache = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
Remove-FolderContents $ChromeCache "Google Chrome cache"

# Firefox
$FirefoxProfiles = "$env:APPDATA\Mozilla\Firefox\Profiles"
if (Test-Path $FirefoxProfiles) {
    Get-ChildItem $FirefoxProfiles -Directory | ForEach-Object {
        Remove-FolderContents "$($_.FullName)\cache2" "Firefox cache ($($_.Name))"
    }
}

# =============================================================
# Event Logs (optional)
# =============================================================
Write-Log ""
$reply = Read-Host "Clear Windows Event Logs? (y/N)"
if ($reply -match '^[Yy]$') {
    Write-Log "Clearing Event Logs..."
    Get-EventLog -List | ForEach-Object {
        try {
            Clear-EventLog -LogName $_.Log -ErrorAction SilentlyContinue
        } catch {}
    }
    Write-Log "Event Logs cleared."
} else {
    Write-Log "Skipping Event Log cleanup."
}

# =============================================================
# Windows built-in Disk Cleanup (cleanmgr)
# =============================================================
Write-Log ""
$reply = Read-Host "Run Windows Disk Cleanup (cleanmgr)? Takes a few minutes (y/N)"
if ($reply -match '^[Yy]$') {
    Write-Log "Running Disk Cleanup..."
    # Set all cleanup flags via registry
    $sageset = 65535
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
    Get-ChildItem $regPath | ForEach-Object {
        Set-ItemProperty -Path $_.PSPath -Name "StateFlags$sageset" -Value 2 -Type DWORD -ErrorAction SilentlyContinue
    }
    Start-Process cleanmgr -ArgumentList "/sagerun:$sageset" -Wait -ErrorAction SilentlyContinue
    Write-Log "Disk Cleanup complete."
} else {
    Write-Log "Skipping Disk Cleanup."
}

# =============================================================
# Summary
# =============================================================
$after = (Get-PSDrive C).Free / 1MB
$freed = [math]::Round($after - $before, 1)

Write-Log ""
Write-Separator
Write-Log "Cleanup complete!"
Write-Log "Approximate space freed: ${freed}MB"
Write-Log "Log saved to $LogFile"
Write-Separator
Write-Host ""
Read-Host "Press ENTER to close"
