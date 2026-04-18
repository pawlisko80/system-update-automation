# =============================================================
# menu.ps1 - Interactive maintenance menu for Windows
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

$ScriptsDir = "C:\scripts"
$Windows    = "$ScriptsDir\windows"

function Write-Header {
    Clear-Host
    $hostName = [System.Net.Dns]::GetHostName()
    $osVer    = (Get-CimInstance Win32_OperatingSystem).Caption -replace "Microsoft Windows ", "Win "
    $arch     = $env:PROCESSOR_ARCHITECTURE
    $info     = "$hostName | $osVer | $arch"
    $interior = 45
    if ($info.Length -gt ($interior - 6)) { $info = $info.Substring(0, $interior - 6) }
    $pad      = " " * [math]::Max(0, ($interior - 5 - $info.Length))
    $border   = "+" + ("=" * $interior) + "+"
    Write-Host ""
    Write-Host "  $border" -ForegroundColor Cyan
    Write-Host "  |     System Maintenance Menu               |" -ForegroundColor Cyan
    Write-Host "  |     $info$pad|" -ForegroundColor Cyan
    Write-Host "  $border" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Menu {
    Write-Header
    Write-Host "  -- Updates ---------------------------------------" -ForegroundColor White
    Write-Host "  " -NoNewline; Write-Host "1" -ForegroundColor Green -NoNewline; Write-Host "  Run full Windows update"
    Write-Host "  " -NoNewline; Write-Host "2" -ForegroundColor Green -NoNewline; Write-Host "  Self-update scripts from GitHub"
    Write-Host "  " -NoNewline; Write-Host "3" -ForegroundColor Green -NoNewline; Write-Host "  Windows cleanup (temp, cache, recycle bin)"
    Write-Host ""
    Write-Host "  -- Health and Security ---------------------------" -ForegroundColor White
    Write-Host "  " -NoNewline; Write-Host "4" -ForegroundColor Green -NoNewline; Write-Host "  System health check"
    Write-Host "  " -NoNewline; Write-Host "5" -ForegroundColor Green -NoNewline; Write-Host "  Security audit"
    Write-Host "  " -NoNewline; Write-Host "6" -ForegroundColor Green -NoNewline; Write-Host "  System inventory"
    Write-Host ""
    Write-Host "  -- Network ---------------------------------------" -ForegroundColor White
    Write-Host "  " -NoNewline; Write-Host "7" -ForegroundColor Green -NoNewline; Write-Host "  Network topology check"
    Write-Host ""
    Write-Host "  -- Reports ---------------------------------------" -ForegroundColor White
    Write-Host "  " -NoNewline; Write-Host "8" -ForegroundColor Green -NoNewline; Write-Host "  Summarize update logs (30 days)"
    Write-Host ""
    Write-Host "  -------------------------------------------------" -ForegroundColor White
    Write-Host "  " -NoNewline; Write-Host "9 / q" -ForegroundColor Red -NoNewline; Write-Host "  Quit"
    Write-Host ""
    Write-Host -NoNewline "  Choose an option: "
}

function Invoke-Script {
    param([string]$Path, [string]$Title)
    Write-Host ""
    Write-Host "  --- $Title ---" -ForegroundColor Cyan
    Write-Host ""
    if (Test-Path $Path) {
        & $Path
    } else {
        Write-Host "  Script not found: $Path" -ForegroundColor Red
        Read-Host "Press ENTER to continue"
    }
}

function Show-LogSummary {
    Write-Host ""
    Write-Host "  --- Update Log Summary ---" -ForegroundColor Cyan
    Write-Host ""
    $LogFile = "$env:USERPROFILE\Documents\logs\windows-maintenance\windows-update.log"
    if (Test-Path $LogFile) {
        $runs    = (Select-String "Windows update started" $LogFile).Count
        $last    = (Select-String "Windows update started" $LogFile | Select-Object -Last 1).Line
        $updates = (Select-String "Installation result: Succeeded" $LogFile).Count
        Write-Host "  Total update runs    : $runs"
        Write-Host "  Successful installs  : $updates"
        Write-Host "  Last run             : $last"
        Write-Host ""
        Write-Host "  Recent log entries:" -ForegroundColor Cyan
        Get-Content $LogFile | Select-Object -Last 20 | ForEach-Object { Write-Host "  $_" }
    } else {
        Write-Host "  No Windows update log found at $LogFile" -ForegroundColor Yellow
    }
    Write-Host ""
    Read-Host "Press ENTER to continue"
}

while ($true) {
    Write-Menu
    $choice = Read-Host
    switch ($choice) {
        "1" { Invoke-Script "$Windows\update-windows.ps1"      "Windows Update" }
        "2" { Invoke-Script "$Windows\self-update.ps1"         "Self-Update Scripts" }
        "3" { Invoke-Script "$Windows\cleanup-windows.ps1"     "Windows Cleanup" }
        "4" { Invoke-Script "$Windows\check-health.ps1"        "System Health Check" }
        "5" { Invoke-Script "$Windows\security-check.ps1"      "Security Audit" }
        "6" { Invoke-Script "$Windows\inventory.ps1"           "System Inventory" }
        "7" { Invoke-Script "$Windows\network-check.ps1"       "Network Check" }
        "8" { Show-LogSummary }
        { $_ -in "9","q","Q" } { Write-Host ""; Write-Host "  Goodbye!"; Write-Host ""; exit 0 }
        default { Write-Host ""; Write-Host "  Invalid option" -ForegroundColor Red; Start-Sleep -Seconds 1 }
    }
}
