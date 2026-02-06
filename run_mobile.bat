@echo off
echo Starting Arbor Med Mobile App in Chrome...
cd mobile
echo Fetching dependencies...
call c:\flutter\bin\flutter.bat pub get
echo Launching App...
call c:\flutter\bin\flutter.bat run -d chrome
if %errorlevel% neq 0 (
    echo "Application exited with error!"
    pause
)
pause
