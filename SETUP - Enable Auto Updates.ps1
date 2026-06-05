# SDC Kiosk — Enable Auto Updates
# Run this ONCE on the kiosk (right-click → Run with PowerShell).
# Registers a Windows Task Scheduler job that checks GitHub every 5 minutes
# and silently updates + relaunches the kiosk if a new version is available.

$AppDir     = Split-Path -Parent $MyInvocation.MyCommand.Definition
$UpdaterScript = Join-Path $AppDir "AUTO-UPDATE.ps1"
$TaskName   = "SDC Kiosk Auto Update"

Write-Host ""
Write-Host "Setting up SDC Kiosk Auto Updater..." -ForegroundColor Cyan

# Remove old task if it exists
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

# Build the task
$action  = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$UpdaterScript`""

$trigger = New-ScheduledTaskTrigger -RepetitionInterval (New-TimeSpan -Minutes 5) -Once -At (Get-Date)

$settings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 2) `
    -MultipleInstances IgnoreNew `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable

$principal = New-ScheduledTaskPrincipal `
    -UserId ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name) `
    -LogonType Interactive `
    -RunLevel Highest

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Principal $principal `
    -Description "Checks GitHub every 5 min and updates the SDC Kiosk app if a new version was pushed." `
    -Force | Out-Null

Write-Host ""
Write-Host "Auto-update task registered!" -ForegroundColor Green
Write-Host ""
Write-Host "How it works:" -ForegroundColor Yellow
Write-Host "  - Every 5 minutes, the kiosk checks GitHub for changes"
Write-Host "  - If Ashley pushes a new version, the kiosk downloads it automatically"
Write-Host "  - Chrome closes and reopens with the new version (takes ~5 seconds)"
Write-Host "  - A log is written to: update-log.txt in the app folder"
Write-Host ""
Write-Host "To disable auto-updates, run:" -ForegroundColor Gray
Write-Host "  Unregister-ScheduledTask -TaskName '$TaskName' -Confirm:`$false" -ForegroundColor Gray
Write-Host ""
Start-Sleep -Seconds 4
