# create-shortcut.ps1 - Creates the "Windows Maintenance" desktop shortcut
# Uses the Store-aware pwsh lookup and the Windows PowerShell icon
# (the Store alias has no icon of its own)
$pwsh = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
if (-not $pwsh) { $pwsh = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" }

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut("$env:USERPROFILE\Desktop\Windows Maintenance.lnk")
$shortcut.TargetPath = $pwsh
$shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"C:\scripts\windows\menu.ps1`""
$shortcut.WorkingDirectory = "C:\scripts"
$shortcut.Description = "System Maintenance Menu"
$shortcut.IconLocation = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe,0"
$shortcut.Save()
Write-Host "Shortcut created on Desktop"
