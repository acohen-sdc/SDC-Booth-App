@echo off
:: ============================================================
::  SDC Kiosk Launcher
::  Opens the kiosk app in true fullscreen kiosk mode.
::  Uses a separate browser profile so regular browser
::  windows are never affected.
::  Tap the SDC logo 5x to exit (touchscreen staff exit).
:: ============================================================

:: Get the folder this batch file lives in (no trailing backslash issue)
set "APP_DIR=%~dp0"
set "APP_FILE=%APP_DIR%SDC Kiosk App - Self Contained.html"
set "KIOSK_PROFILE=%APP_DIR%kiosk-profile"

:: Convert backslashes to forward slashes for file:// URL
set "APP_URL=%APP_FILE:\=/%"

:: ---- Find Brave ----
set "BRAVE="
for %%P in (
  "%PROGRAMFILES%\BraveSoftware\Brave-Browser\Application\brave.exe"
  "%PROGRAMFILES(X86)%\BraveSoftware\Brave-Browser\Application\brave.exe"
  "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\Application\brave.exe"
) do (
  if exist %%P if not defined BRAVE set "BRAVE=%%~P"
)

:: ---- Find Chrome ----
set "CHROME="
for %%P in (
  "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe"
  "%PROGRAMFILES%\Google\Chrome\Application\chrome.exe"
  "%PROGRAMFILES(X86)%\Google\Chrome\Application\chrome.exe"
) do (
  if exist %%P if not defined CHROME set "CHROME=%%~P"
)

:: ---- Find Edge ----
set "EDGE="
for %%P in (
  "%PROGRAMFILES%\Microsoft\Edge\Application\msedge.exe"
  "%PROGRAMFILES(X86)%\Microsoft\Edge\Application\msedge.exe"
  "%LOCALAPPDATA%\Microsoft\Edge\Application\msedge.exe"
) do (
  if exist %%P if not defined EDGE set "EDGE=%%~P"
)

:: ---- Launch Brave ----
if defined BRAVE (
  start "" "%BRAVE%" --kiosk "file:///%APP_URL%" --user-data-dir="%KIOSK_PROFILE%" --no-first-run --disable-pinch --disable-translate --disable-infobars --disable-features=TranslateUI --overscroll-history-navigation=0 --disable-back-forward-cache --disable-session-crashed-bubble --hide-crash-restore-bubble --noerrdialogs --check-for-update-interval=31536000
  goto :done
)

:: ---- Launch Chrome ----
if defined CHROME (
  start "" "%CHROME%" --kiosk "file:///%APP_URL%" --user-data-dir="%KIOSK_PROFILE%" --no-first-run --disable-pinch --disable-translate --disable-infobars --disable-features=TranslateUI --overscroll-history-navigation=0 --disable-back-forward-cache --disable-session-crashed-bubble --hide-crash-restore-bubble --noerrdialogs --check-for-update-interval=31536000
  goto :done
)

:: ---- Launch Edge ----
if defined EDGE (
  start "" "%EDGE%" --kiosk "file:///%APP_URL%" --user-data-dir="%KIOSK_PROFILE%" --no-first-run --disable-pinch --disable-translate --disable-infobars --overscroll-history-navigation=0 --noerrdialogs --edge-kiosk-type=fullscreen
  goto :done
)

:: ---- No browser found ----
echo.
echo ERROR: No supported browser found (Brave, Chrome, or Edge).
echo Please install Brave from https://brave.com
echo.
pause
goto :eof

:done
exit
