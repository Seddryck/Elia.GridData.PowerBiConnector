CD /d %~dp0
SET destination="%userprofile%\documents\Microsoft Power BI Desktop\Custom Connectors\"
XCOPY "Elia.GridData.PowerBiConnector\bin\debug\*.mez" %destination% /Y /F
"C:\Program Files\Microsoft Power BI Desktop\bin\PBIDesktop.exe"
PAUSE