' SDC Kiosk — Silent launcher wrapper
' Double-click this file instead of the .bat to launch with no command window flash.
Set oShell = CreateObject("WScript.Shell")
oShell.Run Chr(34) & Replace(WScript.ScriptFullName, "LAUNCH KIOSK.vbs", "LAUNCH KIOSK.bat") & Chr(34), 0, False
