@echo off
echo Starting Med Buddy Mobile App in Chrome...
cd mobile
echo Fetching dependencies...
call ..\backend\src\flutter\bin\flutter.bat pub get
echo Launching App...
call ..\backend\src\flutter\bin\flutter.bat run -d chrome --web-renderer html
if %errorlevel% neq 0 (
    echo "Application exited with error!"
    pause
)
pause
