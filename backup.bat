@echo off
:: Set your Source and Destination paths
set SRC="C:\Users\Public\Documents"
set DST="E:\Backups\PublicDocuments"
set LOG="C:\Logs\BackupLog.txt"

echo Starting backup via Robocopy...

:: /MIR  - Mirrors a directory tree (deletes targets no longer in source!)
:: /R:3  - Retry 3 times on failed files
:: /W:5  - Wait 5 seconds between retries
:: /LOG+ - Appends output to a log file
robocopy %SRC% %DST% /MIR /R:3 /W:5 /LOG+:%LOG% /NP /TEE

echo Backup complete. Check %LOG% for details.
pause