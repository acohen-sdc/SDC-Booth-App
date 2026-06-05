# SDC Kiosk — Auto Updater
# Runs every 5 minutes via Windows Task Scheduler.
# Pulls latest from GitHub. If the self-contained HTML changed, relaunches Chrome.

$AppDir   = Split-Path -Parent $MyInvocation.MyCommand.Definition
$HtmlFile = Join-Path $AppDir "SDC Kiosk App - Self Contained.html"
$LogFile  = Join-Path $AppDir "update-log.txt"
$VbsFile  = Join-Path $AppDir "LAUNCH KIOSK.vbs"

function Log($msg) {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$ts  $msg" | Out-File -FilePath $LogFile -Append -Encoding utf8
}

Log "--- Auto-update check ---"

# ── 1. Get the hash of the current HTML before pulling ──────────────────────
$hashBefore = $null
if (Test-Path $HtmlFile) {
    $hashBefore = (Get-FileHash $HtmlFile -Algorithm MD5).Hash
}

# ── 2. Git pull ──────────────────────────────────────────────────────────────
try {
    $result = & git -C $AppDir pull origin master 2>&1
    Log "git pull: $result"
} catch {
    Log "ERROR: git pull failed — $_"
    exit 1
}

# ── 3. Check if HTML actually changed ────────────────────────────────────────
$hashAfter = $null
if (Test-Path $HtmlFile) {
    $hashAfter = (Get-FileHash $HtmlFile -Algorithm MD5).Hash
}

if ($hashBefore -eq $hashAfter) {
    Log "No change. Kiosk is up to date."
    exit 0
}

Log "New version detected! Relaunching kiosk..."

# ── 4. Kill Chrome ───────────────────────────────────────────────────────────
$chrome = Get-Process -Name "chrome" -ErrorAction SilentlyContinue
if ($chrome) {
    $chrome | Stop-Process -Force
    Log "Chrome closed."
    Start-Sleep -Seconds 2
}

# ── 5. Relaunch kiosk ────────────────────────────────────────────────────────
if (Test-Path $VbsFile) {
    Start-Process "wscript.exe" -ArgumentList "`"$VbsFile`""
    Log "Kiosk relaunched."
} else {
    Log "ERROR: LAUNCH KIOSK.vbs not found. Cannot relaunch."
    exit 1
}

Log "Update complete."
