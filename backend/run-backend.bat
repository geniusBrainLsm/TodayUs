@echo off
echo ============================================
echo    TodayUs Backend Server Starting...
echo ============================================

REM Load environment variables from .env file
for /f "delims== tokens=1,2" %%G in (..\.env) do set %%G=%%H

REM Set Java Home
set JAVA_HOME=C:\Program Files\Java\jdk-17
set PATH=%JAVA_HOME%\bin;%PATH%

echo 🔧 Environment Variables Loaded:
echo   - DB_USERNAME: %DB_USERNAME%
echo   - DB_PASSWORD: ****
echo   - GOOGLE_CLIENT_ID: %GOOGLE_CLIENT_ID%
echo   - KAKAO_CLIENT_ID: %KAKAO_CLIENT_ID%
echo   - OpenAI API Key: ****%OPENAI_API_KEY:~-4%
echo   - JWT_SECRET: ****

echo.
echo 🔨 Building project...
gradlew.bat clean build -x test

if %ERRORLEVEL% neq 0 (
    echo ❌ Build failed!
    pause
    exit /b 1
)

echo.
echo ✅ Build successful!
echo.
echo 🚀 Starting TodayUs Backend Server on port 8080...
echo    - Database: PostgreSQL (localhost:5432/todayus)
echo    - AI Features: OpenAI GPT Integration ✅
echo    - OAuth2: Google & Kakao Login ✅
echo.

java -jar build\libs\todayus-backend-0.0.1-SNAPSHOT.jar ^
    --server.port=8080 ^
    --spring.profiles.active=local ^
    --DB_USERNAME=%DB_USERNAME% ^
    --DB_PASSWORD=%DB_PASSWORD% ^
    --JWT_SECRET=%JWT_SECRET% ^
    --GOOGLE_CLIENT_ID=%GOOGLE_CLIENT_ID% ^
    --GOOGLE_CLIENT_SECRET=%GOOGLE_CLIENT_SECRET% ^
    --KAKAO_CLIENT_ID=%KAKAO_CLIENT_ID% ^
    --KAKAO_CLIENT_SECRET=%KAKAO_CLIENT_SECRET% ^
    --OPENAI_API_KEY=%OPENAI_API_KEY%

echo.
echo Server stopped.
pause