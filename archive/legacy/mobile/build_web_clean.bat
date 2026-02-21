@echo off
cd /d %~dp0
echo [BUILD] Cleaning previous build...
call flutter clean

echo [BUILD] Fetching dependencies...
call flutter pub get

echo [BUILD] Running Web Release Build...
call flutter build web --release

echo [BUILD] Checking build artifacts...
if exist "build\web\_redirects" (
    echo [SUCCESS] _redirects file found in build directory.
) else (
    echo [WARNING] _redirects file NOT found in build directory. Copying manually...
    copy "web\_redirects" "build\web\_redirects"
)

echo [COMPLETE] Build finished successfully.
echo [INFO] Run "netlify deploy --prod" from the mobile directory to deploy.
