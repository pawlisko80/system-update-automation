# mqtt-common.ps1 - MQTT reporting helpers (Windows)
# Config comes from C:\scripts\.env.local (gitignored). Silent if not configured.

$script:EnvLocal = "C:\scripts\.env.local"
$script:Cfg = @{}
if (Test-Path $script:EnvLocal) {
    Get-Content $script:EnvLocal | ForEach-Object {
        if ($_ -match '^\s*([A-Za-z_]+)\s*=\s*"?([^"#]*?)"?\s*(#.*)?$') {
            $script:Cfg[$Matches[1]] = $Matches[2].Trim()
        }
    }
}

$script:DeviceName = if ($script:Cfg["DEVICE_NAME"]) { $script:Cfg["DEVICE_NAME"] } else { ([System.Net.Dns]::GetHostName()).ToLower() }

function Get-MqttExe {
    $cmd = Get-Command mosquitto_pub -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $p = "C:\Program Files\mosquitto\mosquitto_pub.exe"
    if (Test-Path $p) { return $p }
    return $null
}

function Send-Mqtt {
    param([string]$Topic, [string]$Message)
    $broker = $script:Cfg["MQTT_BROKER"]
    if (-not $broker) { return }
    $exe = Get-MqttExe
    if (-not $exe) { return }
    $prefix = if ($script:Cfg["MQTT_TOPIC_PREFIX"]) { $script:Cfg["MQTT_TOPIC_PREFIX"] } else { "homelab" }
    $port = if ($script:Cfg["MQTT_PORT"]) { $script:Cfg["MQTT_PORT"] } else { "1883" }
    $pubArgs = @("-h", $broker, "-p", $port, "-t", "$prefix/$($script:DeviceName)/$Topic", "-m", $Message, "-q", "1")
    if ($script:Cfg["MQTT_USERNAME"]) { $pubArgs += @("-u", $script:Cfg["MQTT_USERNAME"], "-P", $script:Cfg["MQTT_PASSWORD"]) }
    & $exe @pubArgs *> $null
}

function Send-MqttUpdate {
    param([string]$State, [string]$Summary)
    $ts = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    $loc = if ($script:Cfg["DEVICE_LOCATION"]) { $script:Cfg["DEVICE_LOCATION"] } else { "unknown" }
    $json = @{ device = $script:DeviceName; type = "update"; status = $State; summary = $Summary; timestamp = $ts; location = $loc } | ConvertTo-Json -Compress
    Send-Mqtt "update/status" $json
    Send-Mqtt "update/last_run" $ts
    Send-Mqtt "update/result" $State
}

function Send-MqttHealth {
    param([int]$Issues, [string]$Metrics)
    $ts = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    $state = if ($Issues -gt 0) { "warning" } else { "ok" }
    $json = @{ device = $script:DeviceName; type = "health"; status = $state; issues = $Issues; metrics = $Metrics; timestamp = $ts } | ConvertTo-Json -Compress
    Send-Mqtt "health/status" $json
    Send-Mqtt "health/issues" "$Issues"
    Send-Mqtt "health/last_run" $ts
}

function Send-MqttDisk {
    param([string]$Name, $Percent)
    Send-Mqtt "health/disk_$Name" "$Percent"
}
