# =============================================================
# menu.ps1 — Interactive maintenance menu for Windows
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

$ScriptsDir = "C:\scripts"
$Common     = "$ScriptsDir\common"
$Windows    = "$ScriptsDir\windows"

function Write-Header {
    Clear-Host
    $host_name = $env:COMPUTERNAME
    $os_ver    = (Get-WmiObject Win32_OperatingSystem).Caption -replace "Microsoft Windows ", "Win "
    $arch      = $env:PROCESSOR_ARCHITECTURE
    $info      = "$host_name | $os_ver | $arch"
    if ($info.Length -gt 40) { $info = $info.Substring(0, 40) }
    $pad = " " * (42 - $info.Length)
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║     System Maintenance Menu              ║" -ForegroundColor Cyan
    Write-Host "  ║     $info$pad║" -ForegroundColor Cyan
    Write-Host "  ╚══════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Menu {
    Write-Header
    Write-Host "  ── Updates ──────────────────────────────" -ForegroundColor White
    Write-Host "  " -NoNewline; Write-Host "1" -ForegroundColor Green -NoNewline; Write-Host "  🪟  Run full Windows update"
    Write-Host "  " -NoNewline; Write-Host "2" -ForegroundColor Green -NoNewline; Write-Host "  🔄  Self-update scripts from GitHub"
    Write-Host "  " -NoNewline; Write-Host "3" -ForegroundColor Green -NoNewline; Write-Host "  🧹  Windows cleanup (temp, cache, recycle bin)"
    Write-Host ""
    Write-Host "  ── Health & Security ────────────────────" -ForegroundColor White
    Write-Host "  " -NoNewline; Write-Host "4" -ForegroundColor Green -NoNewline; Write-Host "  💚  System health check"
    Write-Host "  " -NoNewline; Write-Host "5" -ForegroundColor Green -NoNewline; Write-Host "  🔒  Security audit"
    Write-Host "  " -NoNewline; Write-Host "6" -ForegroundColor Green -NoNewline; Write-Host "  📋  System inventory"
    Write-Host ""
    Write-Host "  ── Network ──────────────────────────────" -ForegroundColor White
    Write-Host "  " -NoNewline; Write-Host "7" -ForegroundColor Green -NoNewline; Write-Host "  🌐  Network topology check"
    Write-Host ""
    Write-Host "  ── Reports ──────────────────────────────" -ForegroundColor White
    Write-Host "  " -NoNewline; Write-Host "8" -ForegroundColor Green -NoNewline; Write-Host "  📊  Summarize update logs (30 days)"
    Write-Host ""
    Write-Host "  ────────────────────────────────────────" -ForegroundColor White
    Write-Host "  " -NoNewline; Write-Host "9 / q" -ForegroundColor Red -NoNewline; Write-Host "  Quit"
    Write-Host ""
    Write-Host -NoNewline "  Choose an option: "
}

function Invoke-Script {
    param([string]$Path, [string]$Title)
    Write-Host ""
    Write-Host "━━━ $Title ━━━" -ForegroundColor Cyan
    Write-Host ""
    if (Test-Path $Path) {
        if ($Path -like "*.ps1") {
            & $Path
        } else {
            bash $Path
        }
    } else {
        Write-Host "Script not found: $Path" -ForegroundColor Red
        Read-Host "Press ENTER to continue"
    }
}

# Main loop
while ($true) {
    Write-Menu
    $choice = Read-Host

    switch ($choice) {
        "1" { Invoke-Script "$Windows\update-windows.ps1" "Windows Update" }
        "2" { Invoke-Script "$Windows\self-update.ps1" "Self-Update Scripts" }
        "3" { Invoke-Script "$Windows\cleanup-windows.ps1" "Windows Cleanup" }
        "4" { Invoke-Script "$Common\check-health.sh" "System Health Check" }
        "5" { Invoke-Script "$Common\security-check.sh" "Security Audit" }
        "6" { Invoke-Script "$Common\inventory.sh" "System Inventory" }
        "7" { Invoke-Script "$Common\network-check.sh" "Network Check" }
        "8" { Invoke-Script "$Common\summarize-logs.sh" "Log Summary" }
        { $_ -in "9","q","Q" } {
            Write-Host ""
            Write-Host "Goodbye!"
            Write-Host ""
            exit 0
        }
        default {
            Write-Host ""
            Write-Host "  Invalid option" -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}
