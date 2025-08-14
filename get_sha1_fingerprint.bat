@echo off
echo Getting SHA-1 fingerprint for Google Console...
echo.

REM Check if keytool exists
keytool -help >nul 2>&1
if errorlevel 1 (
    echo ERROR: keytool not found. Please install Java JDK or add it to PATH.
    pause
    exit /b 1
)

echo Android Package Name: com.todayus.todayus_frontend
echo.
echo Generating SHA-1 fingerprint for debug keystore...
echo.

REM Generate SHA-1 fingerprint
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android | findstr SHA1

echo.
echo Instructions:
echo 1. Copy the SHA-1 fingerprint above
echo 2. Go to https://console.cloud.google.com/apis/credentials
echo 3. Select your project
echo 4. Create OAuth 2.0 Client ID for Android
echo 5. Package Name: com.todayus.todayus_frontend
echo 6. SHA-1 Certificate Fingerprint: [paste the fingerprint above]
echo.

pause