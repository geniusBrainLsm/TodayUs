@echo off
echo ==========================================
echo TodayUs 풀스택 배포 스크립트
echo ==========================================

echo.
echo 배포 대상을 선택하세요:
echo 1. 백엔드만 (Railway)
echo 2. 프론트엔드만 (웹)
echo 3. 전체 배포 (백엔드 + 프론트엔드)
set /p DEPLOY_TARGET="선택 (1-3): "

if "%DEPLOY_TARGET%"=="1" goto BACKEND_ONLY
if "%DEPLOY_TARGET%"=="2" goto FRONTEND_ONLY
if "%DEPLOY_TARGET%"=="3" goto FULL_DEPLOY

echo 잘못된 선택입니다.
pause
exit /b 1

:BACKEND_ONLY
echo.
echo ========================================
echo 백엔드 배포 (Railway)
echo ========================================

echo 1. 백엔드 빌드 테스트...
cd backend
call gradlew.bat clean build
if errorlevel 1 (
    echo 백엔드 빌드 실패!
    pause
    exit /b 1
)

echo 2. Docker 빌드 테스트 (선택사항)...
cd ..
echo Docker 빌드를 테스트하시겠습니까? (y/n)
set /p TEST_DOCKER=""
if /i "%TEST_DOCKER%"=="y" (
    docker build -t todayus-backend .
    if errorlevel 1 (
        echo Docker 빌드 실패! Railway에서도 실패할 수 있습니다.
        pause
    ) else (
        echo Docker 빌드 성공!
    )
)

echo 3. Git 커밋 및 푸시...
git add .
git commit -m "Backend deployment ready"
git push origin main

echo.
echo ========================================
echo 백엔드 배포 완료!
echo ========================================
echo.
echo 다음 단계:
echo 1. Railway 대시보드 접속: https://railway.app/dashboard
echo 2. 프로젝트에서 배포 상태 확인
echo 3. 환경 변수 설정 확인
echo 4. Health check 테스트: /actuator/health
echo.
goto END

:FRONTEND_ONLY
echo.
echo ========================================
echo 프론트엔드 웹 배포
echo ========================================

echo 환경을 선택하세요:
echo 1. 개발 환경 (로컬 서버)
echo 2. 스테이징 환경 (Railway 서버)
echo 3. 프로덕션 환경 (Railway 서버)
set /p ENV_CHOICE="환경 선택 (1-3): "

cd frontend

echo 1. Flutter 웹 빌드...
if "%ENV_CHOICE%"=="1" (
    echo 개발 환경으로 빌드합니다.
    flutter build web --release
) else if "%ENV_CHOICE%"=="2" (
    echo 스테이징 환경으로 빌드합니다.
    flutter build web --release --dart-define=ENVIRONMENT=staging
) else (
    echo 프로덕션 환경으로 빌드합니다.
    flutter build web --release --dart-define=ENVIRONMENT=production
)

if errorlevel 1 (
    echo Flutter 웹 빌드 실패!
    pause
    exit /b 1
)

echo 2. Vercel 배포...
echo Vercel CLI가 설치되어 있는지 확인합니다.
where vercel >nul 2>nul
if errorlevel 1 (
    echo Vercel CLI가 설치되지 않았습니다.
    echo npm install -g vercel 명령어로 설치하세요.
    pause
    exit /b 1
)

cd build\web
vercel --prod
if errorlevel 1 (
    echo Vercel 배포 실패!
    pause
    exit /b 1
)

echo.
echo ========================================
echo 프론트엔드 웹 배포 완료!
echo ========================================
echo.
echo 배포된 URL에서 앱을 테스트하세요.
echo CORS 테스트를 통해 백엔드 연결을 확인하세요.
echo.
goto END

:FULL_DEPLOY
echo.
echo ========================================
echo 전체 배포 (백엔드 + 프론트엔드)
echo ========================================

echo 1단계: 백엔드 배포
call :BACKEND_DEPLOY
if errorlevel 1 goto ERROR

echo.
echo 2단계: 백엔드 배포 완료 대기...
echo Railway에서 배포가 완료될 때까지 기다립니다.
echo 배포가 완료되면 아무 키나 누르세요.
pause

echo 3단계: 프론트엔드 웹 빌드 및 배포
cd frontend
echo 프로덕션 환경으로 프론트엔드를 빌드합니다.
flutter build web --release --dart-define=ENVIRONMENT=production
if errorlevel 1 goto ERROR

echo Vercel 배포...
cd build\web
vercel --prod
if errorlevel 1 goto ERROR

echo.
echo ========================================
echo 전체 배포 완료!
echo ========================================
echo.
echo ✅ 백엔드: Railway에서 실행 중
echo ✅ 프론트엔드: Vercel에서 실행 중
echo.
echo 테스트 방법:
echo 1. 프론트엔드 URL에서 앱 접속
echo 2. 환경 설정에서 CORS 테스트 실행
echo 3. 로그인 및 기본 기능 테스트
echo.
goto END

:BACKEND_DEPLOY
cd backend
call gradlew.bat clean build
if errorlevel 1 (
    echo 백엔드 빌드 실패!
    exit /b 1
)
cd ..
git add .
git commit -m "Full stack deployment ready"
git push origin main
exit /b 0

:ERROR
echo.
echo ========================================
echo 배포 중 오류 발생!
echo ========================================
echo.
echo 오류를 확인하고 다시 시도하세요.
echo.
pause
exit /b 1

:END
echo.
echo 배포 스크립트 완료!
pause