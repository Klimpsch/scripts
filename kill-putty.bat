@echo off
echo Terminating all PuTTY sessions...
echo.

:: /F forces termination of the process
:: /IM specifies the image name of the process (putty.exe)
taskkill /F /IM putty.exe

echo.
echo Done.
pause