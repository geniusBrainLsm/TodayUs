@echo off
echo ============================================
echo      🚀 TodayUs Complete Deployment
echo ============================================
echo.

echo 🧹 Cleaning previous builds...
cd frontend
flutter clean
flutter pub get

echo.
echo 📱 Building Android APK...
flutter build apk --release
if %ERRORLEVEL% neq 0 (
    echo ❌ Android build failed!
    pause
    exit /b 1
)

echo.
echo 🌐 Building Web App...
flutter build web --release
if %ERRORLEVEL% neq 0 (
    echo ❌ Web build failed!
    pause
    exit /b 1
)

echo.
echo ✅ All builds completed successfully!
echo.
echo 📦 Generated files:
echo   - Android APK: frontend\build\app\outputs\flutter-apk\app-release.apk
echo   - Web App: frontend\build\web\
echo.
echo 🎉 TodayUs is ready for deployment!
echo.
echo 📋 Next steps:
echo   1. Test the APK on Android device
echo   2. Deploy web app to hosting service
echo   3. For iOS: Use Xcode on macOS to build
echo.

pause