# =============================================================
# network-check.ps1 - Network topology checker for Windows
# Configure HOSTS below with your homelab devices
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

$LogDir  = "$env:USERPROFILE\Documents\logs\network"
$LogFile = "$LogDir\network-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

# =============================================================
# Configuration — add your homelab hosts here
# Format: @{IP="x.x.x.x"; Name="hostname"; Desc="description"}
# =============================================================
$Hosts = @(
    @{IP="10.20.30.1";  Name="router";        Desc="OPNsense Router"},
    @{IP="10.20.30.2";  Name="switch";        Desc="Core Switch"},
    @{IP="10.20.30.10"; Name="nas";           Desc="QNAP NAS"},
    @{IP="10.20.30.20"; Name="proxmox";       Desc="Proxmox Hypervisor"},
    @{IP="10.20.30.25"; Name="hdhomerun";     Desc="HDHomeRun Tuner"},
    @{IP="10.20.30.33"; Name="homeassistant"; Desc="Home Assistant"},
    @{IP="10.20.30.34"; Name="qbittorrent";   Desc="qBittorrent"},
    @{IP="10.20.30.35"; Name="peanut";        Desc="PeaNUT UPS Monitor"}
)

function Write-Log     { param($m) $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"; $line = "[$ts] $m"; Write-Host $line; Add-Content $LogFile $line }
function Write-Ok      { param($m) Write-Host "  OK  $m" -ForegroundColor Green;  Add-Content $LogFile "  OK  $m" }
function Write-Warn    { param($m) Write-Host "  WRN $m" -ForegroundColor Yellow; Add-Content $LogFile "  WRN $m" }
function Write-Crit    { param($m) Write-Host "  ERR $m" -ForegroundColor Red;    Add-Content $LogFile "  ERR $m" }
function Write-Info    { param($m) Write-Host "  INF $m" -ForegroundColor Cyan;   Add-Content $LogFile "  INF $m" }
function Write-Section { param($m) Write-Host ""; Write-Host "--- $m ---" -ForegroundColor Cyan; Add-Content $LogFile ""; Add-Content $LogFile "--- $m ---" }
function Write-Sep     { $l = "=" * 60; Write-Host $l; Add-Content $LogFile $l }

Write-Sep
Write-Log "Network Topology Check - $(Get-Date)"
Write-Log "From: $([System.Net.Dns]::GetHostName())"
Write-Sep

$UpCount   = 0
$DownCount = 0
$Total     = $Hosts.Count

# =============================================================
# Ping all hosts
# =============================================================
Write-Section "Homelab Hosts"
Write-Host ("  {0,-18} {1,-20} {2,-25} {3}" -f "IP", "Name", "Description", "Status")
Write-Host "  $("-" * 70)"

$Hosts | ForEach-Object {
    $ip   = $_.IP
    $name = $_.Name
    $desc = $_.Desc
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
