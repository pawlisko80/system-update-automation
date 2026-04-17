#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Windows maintenance and update automation script.
.DESCRIPTION
    Updates winget packages, Microsoft Store apps, Windows Update,
    and Chocolatey packages in one shot.
.NOTES
    Author: Pawel Majran
    Repo:   https://github.com/pawlisko80/mac-update-automation
    Run as Administrator in PowerShell.
#>

# ============================================================
# Configuration
# ============================================================
$LogDir  = "$env:USERPROFILE\Documents\logs\windows-maintenance"
$LogFile = "$LogDir\windows-update.log"

# ============================================================
# Setup
# ============================================================
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

# ============================================================
# Start
# ============================================================
Write-Separator
Write-Log "Windows update started - $(Get-Date)"
Write-Separator

# ============================================================
# 1. winget
# ============================================================
Write-Log ""
Write-Log "📦 Checking winget..."

if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Log "⬆️  Upgrading winget packages..."
    $wingetOutput = winget upgrade --all --accept-source-agreements --accept-package-agreements 2>&1
    $wingetOutput | ForEach-Object { Write-Log $_ }
    Write-Log "✅ winget upgrade complete."
} else {
    Write-Log "❌ winget not found. Install from Microsoft Store: App Installer."
}

# ============================================================
# 2. Microsoft Store
# ============================================================
Write-Log ""
Write-Log "🛍️  Updating Microsoft Store apps..."

if (Get-Command winget -ErrorAction SilentlyContinue) {
    $storeOutput = winget upgrade --source msstore --accept-source-agreements --accept-package-agreements 2>&1
    $storeOutput | ForEach-Object { Write-Log $_ }
    Write-Log "✅ Microsoft Store update complete."
} else {
    Write-Log "❌ winget not available for Store updates."
}

# ============================================================
# 3. Chocolatey
# ============================================================
Write-Log ""
Write-Log "🍫 Checking Chocolatey..."

if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Log "⬆️  Upgrading Chocolatey packages..."
    $chocoOutput = choco upgrade all -y 2>&1
    $chocoOutput | ForEach-Object { Write-Log $_ }
    Write-Log "✅ Chocolatey upgrade complete."
} else {
    Write-Log "⚠️  Chocolatey not found. Skipping."
    Write-Log "    Install from: https://chocolatey.org/install"
}

# ============================================================
# 4. Windows Update
# ============================================================
Write-Log ""
Write-Log "🪟 Checking Windows Update..."

if (Get-Module -ListAvailable -Name PSWindowsUpdate) {
    Import-Module PSWindowsUpdate
    $updates = Get-WindowsUpdate -MicrosoftUpdate -ErrorAction SilentlyContinue

    if ($updates.Count -gt 0) {
        Write-Log "⚠️  $($updates.Count) Windows update(s) available:"
        $updates | ForEach-Object { Write-Log "   - $($_.Title)" }

        $reply = Read-Host "Press Y to install now, or ENTER to skip"
        if ($reply -match '^[Yy]$') {
            Write-Log "⬆️  Installing Windows updates..."
            $installOutput = Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot:$false 2>&1
            $installOutput | ForEach-Object { Write-Log $_ }
            Write-Log "✅ Windows updates installed. A reboot may be required."
        } else {
            Write-Log "⏭️  Skipping Windows updates."
        }
    } else {
        Write-Log "✅ Windows is up to date."
    }
} else {
    Write-Log "⚠️  PSWindowsUpdate module not found. Installing..."
    Install-Module PSWindowsUpdate -Force -Scope CurrentUser
    Write-Log "✅ PSWindowsUpdate installed. Re-run the script to check for updates."
}

# ============================================================
# Done
# ============================================================
Write-Log ""
Write-Separator
Write-Log "✅ All done! Log saved to $LogFile"
Write-Separator
Write-Host ""
Write-Host "Press ENTER to close..."
Read-Host
