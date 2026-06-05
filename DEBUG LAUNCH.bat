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

echo App folder   : %APP_DIR%
echo HTML file    : %APP_FILE%
echo Kiosk profile: %KIOSK_PROFILE%
echo File URL     : file:///%APP_URL%
echo.

:: Print screen resolution
for /f "tokens=*" %%A in ('powershell -command "(Get-CimInstance -ClassName Win32_VideoController | Select-Object -First 1).CurrentHorizontalResolution"') do set "RES_W=%%A"
for /f "tokens=*" %%A in ('powershell -command "(Get-CimInstance -ClassName Win32_VideoController | Select-Object -First 1).CurrentVerticalResolution"') do set "RES_H=%%A"
echo Screen res   : %RES_W% x %RES_H%
echo.

:: Check HTML exists
if not exist "%APP_FILE%" (
  echo ERROR: HTML file not found at above path!
  echo Please make sure SDC Kiosk App - Self Contained.html is in the same folder.
  pause
  exit
)
echo HTML file: FOUND OK

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
  echo Brave found  : %BRAVE%
  echo.
  echo Launching Brave in kiosk mode...
  start "" "%BRAVE%" --kiosk "file:///%APP_URL%" --user-data-dir="%KIOSK_PROFILE%" --no-first-run --noerrdialogs
  echo Done. Brave should open fullscreen now.
) else (
  echo ERROR: Brave NOT FOUND on this machine!
  echo Install Brave from https://brave.com and try again.
)

echo.
pause
