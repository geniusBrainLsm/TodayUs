@echo off
echo ============================================
echo       🚀 TodayUs Complete Startup
echo ============================================
echo.

echo 📋 Starting all services for TodayUs...
echo.

REM Check if Docker is running
echo 🐳 Checking Docker...
docker version >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ❌ Docker is not running. Please start Docker Desktop first.
    pause
    exit /b 1
)
echo ✅ Docker is running

echo.
echo 🗄️  Starting PostgreSQL database...
docker-compose up -d
if %ERRORLEVEL% neq 0 (
    echo ❌ Failed to start database
    pause
    exit /b 1
)
echo ✅ Database started

echo.
echo ⏳ Waiting for database to be ready...
timeout /t 5 >nul

echo.
echo 🔨 Building and starting backend server...
cd backend
call run-backend.bat
cd ..

echo.
echo 🎉 TodayUs is now running!
echo.
echo 📱 Access points:
echo   - Backend API: http://localhost:8080
echo   - Database: localhost:5432 (todayus/1234)
echo.
echo 💡 To run Flutter app:
echo   cd frontend
echo   flutter run
echo.

pause