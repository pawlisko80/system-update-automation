# =============================================================
# inventory.ps1 - System inventory report for Windows
# Covers: hardware, OS, packages, services, network, security
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

$ReportDir  = "$env:USERPROFILE\Documents\logs\inventory"
$ReportFile = "$ReportDir\inventory-$([System.Net.Dns]::GetHostName())-$(Get-Date -Format 'yyyyMMdd').txt"

if (-not (Test-Path $ReportDir)) { New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null }

function w      { param($m) Write-Host $m; Add-Content $ReportFile $m }
function Section{ param($m) w ""; w "=== $m ===" }

w "============================================================"
w "  System Inventory Report"
w "  Host: $([System.Net.Dns]::GetHostName())"
w "  Generated: $(Get-Date)"
w "============================================================"

# Hardware
Section "Hardware"
$cs  = Get-CimInstance Win32_ComputerSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$ram = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
w "Manufacturer : $($cs.Manufacturer)"
w "Model        : $($cs.Model)"
w "CPU          : $($cpu.Name)"
w "Cores        : $($cpu.NumberOfCores) physical / $($cpu.NumberOfLogicalProcessors) logical"
w "RAM          : ${ram}GB"
w "Architecture : $env:PROCESSOR_ARCHITECTURE"

# OS
Section "OS Details"
$os = Get-CimInstance Win32_OperatingSystem
w "OS           : $($os.Caption)"
w "Version      : $($os.Version)"
w "Build        : $($os.BuildNumber)"
w "Install Date : $($os.InstallDate.ToString('yyyy-MM-dd'))"
w "Last Boot    : $($os.LastBootUpTime.ToString('yyyy-MM-dd HH:mm'))"
$uptime = (Get-Date) - $os.LastBootUpTime
w "Uptime       : $($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m"

# Disk
Section "Disk"
Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -gt 0 } | ForEach-Object {
    $total = $_.Used + $_.Free
    $pct   = [math]::Round(($_.Used / $total) * 100)
    $usedG = [math]::Round($_.Used / 1GB, 1)
    $totG  = [math]::Round($total / 1GB, 1)
    w "$($_.Name): ${usedG}GB used of ${totG}GB (${pct}%)"
}

# Network
Section "Network Interfaces"
Get-NetIPAddress | Where-Object { $_.AddressFamily -eq 'IPv4' -and $_.IPAddress -ne '127.0.0.1' } | ForEach-Object {
    $adapter = Get-NetAdapter -InterfaceIndex $_.InterfaceIndex -ErrorAction SilentlyContinue
    w "$($adapter.Name): $($_.IPAddress)/$($_.PrefixLength) [$($adapter.Status)]"
}

# Installed software
Section "Installed Software (winget)"
if (Get-Command winget -ErrorAction SilentlyContinue) {
    $pkgs = winget list 2>/dev/null
    $pkgs | ForEach-Object { w $_ }
} else {
    w "winget not available"
}

# Chocolatey
Section "Chocolatey Packages"
if (Get-Command choco -ErrorAction SilentlyContinue) {
    choco list 2>/dev/null | ForEach-Object { w $_ }
} else {
    w "Chocolatey not installed"
}

# Running services
Section "Running Services"
Get-Service | Where-Object { $_.Status -eq 'Running' } |
    Sort-Object DisplayName |
    ForEach-Object { w "$($_.Name) - $($_.DisplayName)" }

# Recent logins
Section "Recent Logins"
try {
    Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4624} -MaxEvents 10 -ErrorAction SilentlyContinue |
        ForEach-Object {
            w "$($_.TimeCreated.ToString('yyyy-MM-dd HH:mm')) - $($_.Properties[5].Value)"
        }
} catch {
    w "Could not read login events (enable audit policy)"
}

w ""
w "============================================================"
w "  Report saved to: $ReportFile"
w "============================================================"

Write-Host ""
Write-Host "Inventory complete! Report saved to:" -ForegroundColor Green
Write-Host "  $ReportFile"
Write-Host ""
Read-Host "Press ENTER to close"
