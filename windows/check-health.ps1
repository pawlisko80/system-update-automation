#Requires -RunAsAdministrator
# =============================================================
# check-health.ps1 - System health check for Windows
# Covers: disk, memory, CPU, services, network
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

$LogDir  = "$env:USERPROFILE\Documents\logs\health"
$LogFile = "$LogDir\health-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$Issues  = 0

if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

function Write-Log      { param($m) $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"; $line = "[$ts] $m"; Write-Host $line; Add-Content $LogFile $line }
function Write-Ok       { param($m) Write-Host "  OK  $m" -ForegroundColor Green;   Add-Content $LogFile "  OK  $m" }
function Write-Warn     { param($m) Write-Host "  WRN $m" -ForegroundColor Yellow;  Add-Content $LogFile "  WRN $m"; $script:Issues++ }
function Write-Crit     { param($m) Write-Host "  ERR $m" -ForegroundColor Red;     Add-Content $LogFile "  ERR $m"; $script:Issues++ }
function Write-Info     { param($m) Write-Host "  INF $m" -ForegroundColor Cyan;    Add-Content $LogFile "  INF $m" }
function Write-Section  { param($m) Write-Host ""; Write-Host "--- $m ---" -ForegroundColor Cyan; Add-Content $LogFile ""; Add-Content $LogFile "--- $m ---" }
function Write-Sep      { $l = "=" * 60; Write-Host $l; Add-Content $LogFile $l }

Write-Sep
Write-Log "System Health Check - $(Get-Date)"
Write-Log "Host: $([System.Net.Dns]::GetHostName()) | $env:PROCESSOR_ARCHITECTURE"
Write-Sep

# =============================================================
# Uptime
# =============================================================
Write-Section "Uptime"
$os      = Get-CimInstance Win32_OperatingSystem
$uptime  = (Get-Date) - $os.LastBootUpTime
Write-Ok "Uptime: $($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m (last boot: $($os.LastBootUpTime.ToString('yyyy-MM-dd HH:mm')))"

# =============================================================
# Disk Usage
# =============================================================
Write-Section "Disk Usage"
Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -gt 0 } | ForEach-Object {
    $total = $_.Used + $_.Free
    $pct   = [math]::Round(($_.Used / $total) * 100)
    $usedG = [math]::Round($_.Used / 1GB, 1)
    $totG  = [math]::Round($total / 1GB, 1)
    $msg   = "$($_.Name): $pct% used (${usedG}GB of ${totG}GB)"
    if ($pct -ge 90)     { Write-Crit "CRITICAL: $msg" }
    elseif ($pct -ge 80) { Write-Warn "WARNING: $msg" }
    else                 { Write-Ok $msg }
}

# =============================================================
# Memory
# =============================================================
Write-Section "Memory"
$mem     = Get-CimInstance Win32_OperatingSystem
$totalGB = [math]::Round($mem.TotalVisibleMemorySize / 1MB, 1)
$freeGB  = [math]::Round($mem.FreePhysicalMemory / 1MB, 1)
$usedPct = [math]::Round((($mem.TotalVisibleMemorySize - $mem.FreePhysicalMemory) / $mem.TotalVisibleMemorySize) * 100)
Write-Ok "Total RAM: ${totalGB}GB | Free: ${freeGB}GB | Used: ${usedPct}%"
if ($usedPct -ge 90)     { Write-Crit "Memory usage critical: ${usedPct}%" }
elseif ($usedPct -ge 75) { Write-Warn "Memory usage high: ${usedPct}%" }

# =============================================================
# CPU Load
# =============================================================
Write-Section "CPU Load"
$cpu = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
$msg = "CPU load: ${cpu}%"
if ($cpu -ge 90)     { Write-Crit $msg }
elseif ($cpu -ge 75) { Write-Warn $msg }
else                 { Write-Ok $msg }

# =============================================================
# Failed Services
# =============================================================
Write-Section "Services"
$failed = Get-Service | Where-Object { $_.Status -eq 'Stopped' -and $_.StartType -eq 'Automatic' } |
    Where-Object { $_.Name -notmatch 'OneSyncSvc|CDPUserSvc|WpnUserService|PrintWorkflow|cbdhsvc|edgeupdate|MapsBroker|sppsvc|gupdate|MicrosoftEdgeElevationService' }
if ($failed.Count -gt 0) {
    Write-Warn "$($failed.Count) automatic service(s) not running:"
    $failed | ForEach-Object { Write-Info "  - $($_.Name) ($($_.DisplayName))" }
} else {
    Write-Ok "All automatic services running"
}

# =============================================================
# Windows Update status
# =============================================================
Write-Section "Windows Update"
try {
    $Session  = New-Object -ComObject Microsoft.Update.Session
    $Searcher = $Session.CreateUpdateSearcher()
    $Results  = $Searcher.Search("IsInstalled=0")
    $count    = $Results.Updates.Count
    if ($count -gt 0) {
        Write-Warn "$count Windows update(s) pending"
        $Results.Updates | ForEach-Object { Write-Info "  - $($_.Title)" }
    } else {
        Write-Ok "Windows is up to date"
    }
} catch {
    Write-Info "Could not check Windows Update: $_"
}

# =============================================================
# Network
# =============================================================
Write-Section "Network"
$gw = (Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue | Sort-Object RouteMetric | Select-Object -First 1).NextHop
if ($gw) {
    if (Test-Connection $gw -Count 1 -Quiet -ErrorAction SilentlyContinue) {
        Write-Ok "Gateway $gw reachable"
    } else {
        Write-Crit "Gateway $gw unreachable"
    }
}
if (Test-Connection 8.8.8.8 -Count 1 -Quiet -ErrorAction SilentlyContinue) {
    Write-Ok "Internet connectivity: OK"
} else {
    Write-Crit "No internet connectivity"
}
# DNS check
try {
    [System.Net.Dns]::GetHostAddresses("github.com") | Out-Null
    Write-Ok "DNS resolution: OK"
} catch {
    Write-Warn "DNS resolution failed"
}

# =============================================================
# Summary
# =============================================================
Write-Host ""
Write-Sep
if ($Issues -eq 0) {
    Write-Host "  OK  Health check passed - no issues found" -ForegroundColor Green
    Add-Content $LogFile "  OK  Health check passed - no issues found"
} else {
    Write-Host "  ERR Health check complete - $Issues issue(s) found" -ForegroundColor Red
    Add-Content $LogFile "  ERR Health check complete - $Issues issue(s) found"
}
Write-Log "Log saved to $LogFile"
Write-Sep
Write-Host ""
Read-Host "Press ENTER to close"
