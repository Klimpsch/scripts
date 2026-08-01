@echo off
set LOGFILE="%USERPROFILE%\Desktop\SysDiag_%COMPUTERNAME%.txt"

echo Generating report... Please wait...

echo === SYSTEM INFO === > %LOGFILE%
systeminfo | findstr /B /C:"OS Name" /C:"OS Version" /C:"System Boot Time" >> %LOGFILE%

echo. >> %LOGFILE%
echo === NETWORK CONFIG === >> %LOGFILE%
ipconfig /all >> %LOGFILE%

echo. >> %LOGFILE%
echo === ACTIVE CONNECTIONS === >> %LOGFILE%
netstat -ano >> %LOGFILE%

echo. >> %LOGFILE%
echo === DOMAIN / LOGON SERVER === >> %LOGFILE%
echo Logon Server: %LOGONSERVER% >> %LOGFILE%
echo User Domain: %USERDOMAIN% >> %LOGFILE%

echo Report saved to Desktop as SysDiag_%COMPUTERNAME%.txt
pause