@echo off
echo Loading environment variables from .env...

REM Set environment variables
set DB_USERNAME=todayus
set DB_PASSWORD=1234
set KAKAO_CLIENT_ID=e74f4850d8af7e2b2aec20f4faa636b3
set KAKAO_CLIENT_SECRET=IOSjbcQZbcrB1NptoM85i9mHf1fRM5al
set GOOGLE_CLIENT_ID=347489897525-igcnhikahp5fsn19obcdkmch061aom37.apps.googleusercontent.com
set GOOGLE_CLIENT_SECRET=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
set JWT_SECRET=myVerySecretKeyForJWTTokenGeneration123456789

echo Environment variables set. Starting Spring Boot application...
echo KAKAO_CLIENT_ID=%KAKAO_CLIENT_ID%
echo.

gradlew.bat bootRun