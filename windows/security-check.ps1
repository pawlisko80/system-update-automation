#Requires -RunAsAdministrator
# =============================================================
# security-check.ps1 - Security audit for Windows
# Covers: failed logins, firewall, open ports, updates, users
# Repo: https://github.com/pawlisko80/system-update-automation
# =============================================================

$LogDir  = "$env:USERPROFILE\Documents\logs\security"
$LogFile = "$LogDir\security-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$Issues  = 0

if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

function Write-Log     { param($m) $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"; $line = "[$ts] $m"; Write-Host $line; Add-Content $LogFile $line }
function Write-Ok      { param($m) Write-Host "  OK  $m" -ForegroundColor Green;  Add-Content $LogFile "  OK  $m" }
function Write-Warn    { param($m) Write-Host "  WRN $m" -ForegroundColor Yellow; Add-Content $LogFile "  WRN $m"; $script:Issues++ }
function Write-Crit    { param($m) Write-Host "  ERR $m" -ForegroundColor Red;    Add-Content $LogFile "  ERR $m"; $script:Issues++ }
function Write-Info    { param($m) Write-Host "  INF $m" -ForegroundColor Cyan;   Add-Content $LogFile "  INF $m" }
function Write-Section { param($m) Write-Host ""; Write-Host "--- $m ---" -ForegroundColor Cyan; Add-Content $LogFile ""; Add-Content $LogFile "--- $m ---" }
function Write-Sep     { $l = "=" * 60; Write-Host $l; Add-Content $LogFile $l }

Write-Sep
Write-Log "Security Audit - $(Get-Date)"
Write-Log "Host: $([System.Net.Dns]::GetHostName())"
Write-Sep

# =============================================================
# Failed Login Attempts
# =============================================================
Write-Section "Failed Login Attempts (last 24h)"
try {
    $since  = (Get-Date).AddHours(-24)
    $failed = Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625; StartTime=$since} -ErrorAction SilentlyContinue
    $count  = if ($failed) { $failed.Count } else { 0 }
    if ($count -gt 100)     { Write-Crit "High failed login attempts in last 24h: $count" }
    elseif ($count -gt 10)  { Write-Warn "Failed login attempts in last 24h: $count" }
    else                    { Write-Ok "Failed login attempts (24h): $count" }

    if ($count -gt 0) {
        $failed | Group-Object { $_.Properties[19].Value } |
            Sort-Object Count -Descending | Select-Object -First 5 |
            ForEach-Object { Write-Info "  $($_.Count) attempts from: $($_.Name)" }
    }
} catch {
    Write-Info "Could not read Security event log (may need audit policy enabled)"
}

# =============================================================
# Windows Firewall
# =============================================================
Write-Section "Windows Firewall"
try {
    $profiles = Get-NetFirewallProfile
    $profiles | ForEach-Object {
        if ($_.Enabled) {
            Write-Ok "Firewall $($_.Name): Enabled"
        } else {
            Write-Crit "Firewall $($_.Name): DISABLED"
        }
    }
} catch {
    Write-Info "Could not check firewall status: $_"
}

# =============================================================
# Open Ports
# =============================================================
Write-Section "Listening Ports"
try {
    $listeners = Get-NetTCPConnection -State Listen |
        Select-Object LocalAddress, LocalPort, OwningProcess |
        Sort-Object LocalPort
    $listeners | ForEach-Object {
        $proc = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
        $name = if ($proc) { $proc.Name } else { "unknown" }
        Write-Info "Port $($_.LocalPort) ($($_.LocalAddress)) - $name (PID $($_.OwningProcess))"
    }
} catch {
    Write-Info "Could not enumerate listening ports: $_"
}

# =============================================================
# Pending Security Updates
# =============================================================
Write-Section "Pending Security Updates"
try {
    $Session  = New-Object -ComObject Microsoft.Update.Session
    $Searcher = $Session.CreateUpdateSearcher()
    $Results  = $Searcher.Search("IsInstalled=0 and Type='Software'")
    $security = $Results.Updates | Where-Object { $_.AutoSelectOnWebSites -eq $true }
    if ($security.Count -gt 0) {
        Write-Warn "$($security.Count) security update(s) pending:"
        $security | ForEach-Object { Write-Info "  - $($_.Title)" }
    } else {
        Write-Ok "No pending security updates"
    }
} catch {
    Write-Info "Could not check Windows Update: $_"
}

# =============================================================
# Local Admin Accounts
# =============================================================
Write-Section "Local Administrator Accounts"
try {
    $admins = Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue
    Write-Info "Members of Administrators group:"
    $admins | ForEach-Object { Write-Info "  - $($_.Name) ($($_.ObjectClass))" }
    if ($admins.Count -gt 2) {
        Write-Warn "More than 2 administrator accounts — verify all are expected"
    } else {
        Write-Ok "Administrator account count looks normal: $($admins.Count)"
    }
} catch {
    Write-Info "Could not enumerate admin accounts: $_"
}

# =============================================================
# Secrets scan in scripts folder
# =============================================================
Write-Section "Secrets Scan (C:\scripts)"
$patterns = @("password\s*=\s*['""]", "api[_-]key\s*=\s*['""]", "secret\s*=\s*['""]", "token\s*=\s*['""]")
$found = 0
$patterns | ForEach-Object {
    $matches = Get-ChildItem "C:\scripts" -Recurse -Include "*.ps1","*.sh","*.txt" -ErrorAction SilentlyContinue |
        Select-String -Pattern $_ -ErrorAction SilentlyContinue |
        Where-Object { $_.Path -notmatch "CHANGELOG|README|notify" }
    if ($matches) {
        Write-Warn "Potential secret found (pattern: $_)"
        $matches | Select-Object -First 3 | ForEach-Object { Write-Info "  $($_.Path):$($_.LineNumber)" }
        $found++
    }
}
if ($found -eq 0) { Write-Ok "No obvious secrets found in C:\scripts" }

# =============================================================
# Summary
# =============================================================
Write-Host ""
Write-Sep
if ($Issues -eq 0) {
    Write-Host "  OK  Security check passed - no issues found" -ForegroundColor Green
    Add-Content $LogFile "  OK  Security check passed - no issues found"
} else {
    Write-Host "  ERR Security check complete - $Issues issue(s) found" -ForegroundColor Red
    Add-Content $LogFile "  ERR Security check complete - $Issues issue(s) found"
}
Write-Log "Log saved to $LogFile"
Write-Sep
Write-Host ""
Read-Host "Press ENTER to close"
