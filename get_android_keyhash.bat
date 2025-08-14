@echo off
echo Getting Android Debug Key Hash for Kakao Console...
echo.

REM Check if keytool exists
keytool -help >nul 2>&1
if errorlevel 1 (
    echo ERROR: keytool not found. Please install Java JDK or add it to PATH.
    pause
    exit /b 1
)

REM Check if openssl exists  
openssl version >nul 2>&1
if errorlevel 1 (
    echo ERROR: openssl not found. Please install OpenSSL or Git Bash.
    echo.
    echo Alternative method: Use Git Bash and run:
    echo keytool -exportcert -alias androiddebugkey -keystore "%USERPROFILE%\.android\debug.keystore" -storepass android -keypass android ^| openssl sha1 -binary ^| openssl base64
    pause
    exit /b 1
)

echo Generating Android Debug Key Hash...
echo.

REM Generate key hash
keytool -exportcert -alias androiddebugkey -keystore "%USERPROFILE%\.android\debug.keystore" -storepass android -keypass android | openssl sha1 -binary | openssl base64

echo.
echo Copy the key hash above and paste it in Kakao Console:
echo 1. Go to https://developers.kakao.com/console/app
echo 2. Select your app
echo 3. Go to App Settings ^> Platform
echo 4. Add Android platform
echo 5. Package Name: com.example.todayus_frontend
echo 6. Key Hash: [paste the hash above]

pause