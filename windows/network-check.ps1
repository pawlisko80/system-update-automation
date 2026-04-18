# =============================================================
# network-check.ps1 - Network topology checker for Windows
# Reads hosts from common/hosts.conf
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

$ScriptsDir = "C:\scripts"
$HostsConf  = "$ScriptsDir\common\hosts.conf"
$LogDir     = "$env:USERPROFILE\Documents\logs\network"
$LogFile    = "$LogDir\network-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

function Write-Log     { param($m) $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"; $line = "[$ts] $m"; Write-Host $line; Add-Content $LogFile $line }
function Write-Ok      { param($m) Write-Host "  OK  $m" -ForegroundColor Green;  Add-Content $LogFile "  OK  $m" }
function Write-Crit    { param($m) Write-Host "  ERR $m" -ForegroundColor Red;    Add-Content $LogFile "  ERR $m" }
function Write-Info    { param($m) Write-Host "  INF $m" -ForegroundColor Cyan;   Add-Content $LogFile "  INF $m" }
function Write-Section { param($m) Write-Host ""; Write-Host "--- $m ---" -ForegroundColor Cyan; Add-Content $LogFile ""; Add-Content $LogFile "--- $m ---" }
function Write-Sep     { $l = "=" * 60; Write-Host $l; Add-Content $LogFile $l }

# Check hosts.conf exists
if (-not (Test-Path $HostsConf)) {
    Write-Host "ERROR: hosts.conf not found at $HostsConf" -ForegroundColor Red
    Write-Host "Create it with format: IP|Name|Description"
    Read-Host "Press ENTER to close"
    exit 1
}

Write-Sep
Write-Log "Network Topology Check - $(Get-Date)"
Write-Log "From: $([System.Net.Dns]::GetHostName())"
Write-Log "Config: $HostsConf"
Write-Sep

$UpCount   = 0
$DownCount = 0
$Total     = 0

# =============================================================
# Parse hosts.conf and ping all hosts
# =============================================================
Write-Section "Homelab Hosts"
Write-Host ("  {0,-18} {1,-20} {2,-25} {3}" -f "IP", "Name", "Description", "Status")
Write-Host "  $("-" * 70)"

Get-Content $HostsConf | ForEach-Object {
    $line = $_.Trim()
    # Skip comments and empty lines
    if ($line -match '^#' -or $line -eq '') { return }

    $parts = $line -split '\|'
    if ($parts.Count -lt 3) { return }

    $ip   = $parts[0].Trim()
    $name = $parts[1].Trim()
    $desc = $parts[2].Trim()
    $Total++

    $result = Test-Connection $ip -Count 1 -ErrorAction SilentlyContinue
    if ($result) {
        $latency = $result.ResponseTime
        Write-Host ("  {0,-18} {1,-20} {2,-25} " -f $ip, $name, $desc) -NoNewline
        Write-Host "UP (${latency}ms)" -ForegroundColor Green
        Add-Content $LogFile ("  {0,-18} {1,-20} {2,-25} UP ({3}ms)" -f $ip, $name, $desc, $latency)
        $UpCount++
    } else {
        Write-Host ("  {0,-18} {1,-20} {2,-25} " -f $ip, $name, $desc) -NoNewline
        Write-Host "DOWN" -ForegroundColor Red
        Add-Content $LogFile ("  {0,-18} {1,-20} {2,-25} DOWN" -f $ip, $name, $desc)
        $DownCount++
    }
}

# =============================================================
# DNS check
# =============================================================
Write-Section "DNS Resolution"
@("google.com", "github.com", "anthropic.com") | ForEach-Object {
    try {
        [System.Net.Dns]::GetHostAddresses($_) | Out-Null
        Write-Ok "DNS: $_ resolved"
    } catch {
        Write-Crit "DNS: $_ failed"
    }
}

# =============================================================
# Internet latency
# =============================================================
Write-Section "Internet Latency"
@(
    @{IP="8.8.8.8";  Name="Google DNS"},
    @{IP="1.1.1.1";  Name="Cloudflare DNS"},
    @{IP="9.9.9.9";  Name="Quad9 DNS"}
) | ForEach-Object {
    $results = Test-Connection $_.IP -Count 3 -ErrorAction SilentlyContinue
    if ($results) {
        $avg = [math]::Round(($results | Measure-Object ResponseTime -Average).Average)
        Write-Ok "$($_.Name) ($($_.IP)): ${avg}ms avg"
    } else {
        Write-Crit "$($_.Name) ($($_.IP)): unreachable"
    }
}

# =============================================================
# Summary
# =============================================================
Write-Host ""
Write-Sep
Write-Log "Results: $UpCount/$Total hosts up, $DownCount down"
if ($DownCount -eq 0) {
    Write-Host "  OK  All hosts reachable" -ForegroundColor Green
} else {
    Write-Host "  ERR $DownCount host(s) unreachable" -ForegroundColor Red
}
Write-Log "Log saved to $LogFile"
Write-Sep
Write-Host ""
Read-Host "Press ENTER to close"
