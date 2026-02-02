@echo off
echo 🚀 Launching Android Emulator: Medium_Phone_API_36.1...
start "" "c:\Users\shuba\Desktop\Med_buddy\backend\src\flutter\bin\flutter.bat" emulators --launch Medium_Phone_API_36.1

echo ⏳ Waiting for emulator to boot (40s)...
timeout /t 40 /nobreak

echo 📲 Running App in Debug Mode (Hot Reload Enabled)...
echo ⚠️  Ensure your backend is running: 'npm run dev' in separate terminal
cd mobile
call ..\backend\src\flutter\bin\flutter.bat run -d android
pause
