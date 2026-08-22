@echo off
echo ==========================================
echo   REFRESHING NETWORK ADAPTER & DNS
echo ==========================================
echo.

echo [1/4] Releasing IP address...
ipconfig /release >nul

echo [2/4] Flushing DNS Cache...
ipconfig /flushdns

echo [3/4] Renewing IP address...
ipconfig /renew >nul

echo [4/4] Registering DNS...
ipconfig /registerdns

echo.
echo Network stack refreshed successfully.
pause