@echo off
echo ========================================
echo Context Keeper - Debug Installation
echo ========================================
echo.

echo [1/5] Checking ADB connection...
adb devices
echo.

echo [2/5] Uninstalling old version...
adb uninstall com.example.context_keeper
echo.

echo [3/5] Clearing logcat...
adb logcat -c
echo.

echo [4/5] Installing new APK...
adb install -r build\app\outputs\flutter-apk\app-release.apk
echo.

echo [5/5] Starting logcat filter (press Ctrl+C to stop)...
echo.
echo Watching for: 🚀 🔐 🗄️ 📝 📞 🔔 ✅ ❌ ⚠️ 🔒
echo.
adb logcat | findstr "🚀 🔐 🗄️ 📝 📞 🔔 ✅ ❌ ⚠️ 🔒 MainActivity"
