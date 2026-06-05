@echo off
echo =============================================
echo  SDC Kiosk - DEBUG LAUNCHER
echo  This shows any errors so we can fix them.
echo =============================================
echo.

set "APP_DIR=%~dp0"
set "APP_FILE=%APP_DIR%SDC Kiosk App - Self Contained.html"
set "KIOSK_PROFILE=%APP_DIR%kiosk-profile"
set "APP_URL=%APP_FILE:\=/%"

echo App folder  : %APP_DIR%
echo HTML file   : %APP_FILE%
echo Kiosk profile: %KIOSK_PROFILE%
echo File URL    : file:///%APP_URL%
echo.

:: Check HTML exists
if not exist "%APP_FILE%" (
  echo ERROR: HTML file not found at above path!
  pause
  exit
)
echo HTML file found OK.

:: Find Brave
set "BRAVE="
for %%P in (
  "%PROGRAMFILES%\BraveSoftware\Brave-Browser\Application\brave.exe"
  "%PROGRAMFILES(X86)%\BraveSoftware\Brave-Browser\Application\brave.exe"
  "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\Application\brave.exe"
) do (
  if exist %%P if not defined BRAVE set "BRAVE=%%~P"
)

if defined BRAVE (
  echo Brave found : %BRAVE%
  echo.
  echo Launching Brave in kiosk mode...
  echo.
  start "" "%BRAVE%" --kiosk "file:///%APP_URL%" --user-data-dir="%KIOSK_PROFILE%" --no-first-run --noerrdialogs
  echo Launch command sent. Check if Brave opened.
) else (
  echo ERROR: Brave not found on this machine!
)

echo.
pause
