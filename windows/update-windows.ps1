#Requires -RunAsAdministrator
param()

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$LogDir  = "$env:USERPROFILE\Documents\logs\windows-maintenance"
$LogFile = "$LogDir\windows-update.log"

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

function Get-ResultDescription {
    param([int]$Code)
    switch ($Code) {
        0 { return "Not started" }
        1 { return "In progress" }
        2 { return "Succeeded" }
        3 { return "Succeeded with errors" }
        4 { return "Failed" }
        5 { return "Aborted" }
        default { return "Unknown ($Code)" }
    }
}

function Should-LogLine {
    param([string]$Line)
    $trimmed = $Line.Trim()
    if ($trimmed -eq '') { return $false }
    if ($trimmed -match '^[\-\\|/]+$') { return $false }
    if ($trimmed -match '^\d+(\.\d+)?\s*(KB|MB|GB)\s*/') { return $false }
    if ($trimmed -match '^\s*\d+\s*%\s*$') { return $false }
    if ($trimmed -match '^\s+$') { return $false }
    return $true
}

Write-Separator
Write-Log "Windows update started - $(Get-Date)"
Write-Separator

# winget
Write-Log ""
Write-Log "Checking winget..."
if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Log "Upgrading all packages..."
    $out = winget upgrade --all --accept-source-agreements --accept-package-agreements --disable-interactivity --exclude Microsoft.Edge 2>&1
    $out | ForEach-Object {
        $clean = ($_ -replace '[^\x20-\x7E]', '').Trim()
        if (Should-LogLine $clean) { Write-Log $clean }
    }
    Write-Log "winget upgrade complete."
} else {
    Write-Log "winget not found. Install App Installer from Microsoft Store."
}

# Chocolatey
Write-Log ""
Write-Log "Checking Chocolatey..."
if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Log "Upgrading Chocolatey packages..."
    $out = choco upgrade all -y 2>&1
    $out | ForEach-Object {
        $clean = $_.Trim()
        if (Should-LogLine $clean) { Write-Log $clean }
    }
    Write-Log "Chocolatey upgrade complete."
} else {
    Write-Log "Chocolatey not found. Skipping."
}

# Windows Update via native COM (ARM64 compatible)
Write-Log ""
Write-Log "Checking Windows Update..."
try {
    $Session = New-Object -ComObject Microsoft.Update.Session
    $Searcher = $Session.CreateUpdateSearcher()
    $Results = $Searcher.Search("IsInstalled=0")
    $updates = $Results.Updates

    if ($updates.Count -gt 0) {
        Write-Log "$($updates.Count) Windows update(s) available:"
        $updates | ForEach-Object { Write-Log "   - $($_.Title)" }

        $reply = Read-Host "Press Y to install now, or ENTER to skip"
        if ($reply -match '^[Yy]$') {
            Write-Log "Installing Windows updates..."
            $Downloader = $Session.CreateUpdateDownloader()
            $Downloader.Updates = $updates
            Write-Log "Downloading updates..."
            $Downloader.Download() | Out-Null
            $Installer = $Session.CreateUpdateInstaller()
            $Installer.Updates = $updates
            Write-Log "Installing updates..."
            $Result = $Installer.Install()
            $desc = Get-ResultDescription $Result.ResultCode
            Write-Log "Installation result: $desc"
            if ($Result.RebootRequired) {
                Write-Log "A reboot is required to complete installation."
            } else {
                Write-Log "No reboot required."
            }
        } else {
            Write-Log "Skipping Windows updates."
        }
    } else {
        Write-Log "Windows is up to date."
    }
} catch {
    Write-Log "Windows Update check failed: $_"
}

Write-Log ""
Write-Separator
Write-Log "All done! Log saved to $LogFile"
Write-Separator
Write-Host ""
Read-Host "Press ENTER to close"

