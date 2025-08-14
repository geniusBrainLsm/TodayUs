@echo off
echo ===============================
echo TodayUs Railway 배포 스크립트
echo ===============================

echo.
echo 1. 백엔드 빌드 테스트 중...
cd backend

echo.
echo Gradle 빌드 중...
call gradlew.bat clean build

if errorlevel 1 (
    echo 빌드 실패! 오류를 확인하세요.
    pause
    exit /b 1
)

echo.
echo 빌드 성공!

echo.
echo Railway CLI 설치 확인 중...
where railway >nul 2>nul
if errorlevel 1 (
    echo Railway CLI가 설치되지 않았습니다.
    echo npm install -g @railway/cli 명령어로 설치하세요.
    pause
    exit /b 1
)

echo.
echo Railway 로그인 상태 확인 중...
railway whoami
if errorlevel 1 (
    echo Railway에 로그인이 필요합니다.
    railway login
    if errorlevel 1 (
        echo 로그인 실패!
        pause
        exit /b 1
    )
)

echo.
echo 프로젝트 배포 중...
railway up

if errorlevel 1 (
    echo 배포 실패!
    pause
    exit /b 1
)

echo.
echo ===============================
echo 배포 완료!
echo ===============================
echo.
echo 다음 단계:
echo 1. Railway 대시보드에서 환경 변수 설정
echo 2. 데이터베이스 연결 확인
echo 3. 도메인 설정 (선택사항)
echo.
echo Railway 대시보드: https://railway.app/dashboard
echo.

cd ..
pause