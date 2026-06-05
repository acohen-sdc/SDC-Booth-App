# SDC Kiosk — Creates a desktop shortcut that launches the kiosk silently
# Right-click this file and choose "Run with PowerShell" on the kiosk machine.

$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Definition
$VbsPath    = Join-Path $ScriptDir "LAUNCH KIOSK.vbs"
$Desktop    = [Environment]::GetFolderPath("CommonDesktopDirectory")  # All-users desktop
$Shortcut   = Join-Path $Desktop "SDC Kiosk.lnk"

$WshShell   = New-Object -ComObject WScript.Shell
$Link       = $WshShell.CreateShortcut($Shortcut)
$Link.TargetPath       = "wscript.exe"
$Link.Arguments        = "`"$VbsPath`""
$Link.WorkingDirectory = $ScriptDir
$Link.Description      = "SDC Automation Kiosk — Automate 2026"
$Link.WindowStyle      = 1

# Use Chrome icon if available, otherwise default
$ChromePath = "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
if (Test-Path $ChromePath) { $Link.IconLocation = "$ChromePath,0" }

$Link.Save()

Write-Host "Desktop shortcut created: $Shortcut" -ForegroundColor Green
Write-Host "Double-click 'SDC Kiosk' on the desktop to launch." -ForegroundColor Cyan
Start-Sleep -Seconds 3
