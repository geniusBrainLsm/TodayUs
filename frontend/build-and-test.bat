@echo off
echo ================================
echo TodayUs Flutter 빌드 및 테스트
echo ================================

set /p BUILD_TYPE="빌드 타입을 선택하세요 (1: 디버그, 2: 릴리즈): "

if "%BUILD_TYPE%"=="1" (
    echo 디버그 모드로 빌드합니다...
    set BUILD_MODE=debug
    set BUILD_COMMAND=flutter run
) else if "%BUILD_TYPE%"=="2" (
    echo 릴리즈 모드로 빌드합니다...
    set BUILD_MODE=release
    set BUILD_COMMAND=flutter build apk --release
) else (
    echo 잘못된 선택입니다. 디버그 모드로 진행합니다.
    set BUILD_MODE=debug
    set BUILD_COMMAND=flutter run
)

echo.
echo 환경을 선택하세요:
echo 1. 개발 환경 (로컬 서버 - 에뮬레이터용)
echo 2. 개발 환경 (로컬 서버 - 실제 디바이스용)
echo 3. 스테이징 환경 (Railway 서버)
echo 4. 프로덕션 환경 (Railway 서버)
set /p ENV_TYPE="환경 선택 (1-4): "

cd /d "%~dp0"

echo.
echo Dependencies 업데이트 중...
flutter pub get

if errorlevel 1 (
    echo Dependencies 업데이트 실패!
    pause
    exit /b 1
)

echo.
echo 코드 분석 중...
flutter analyze

if errorlevel 1 (
    echo 코드 분석 중 오류 발견! 계속하시겠습니까?
    set /p CONTINUE="계속하시겠습니까? (y/n): "
    if /i not "%CONTINUE%"=="y" (
        pause
        exit /b 1
    )
)

echo.
if "%ENV_TYPE%"=="2" (
    echo ==============================
    echo 실제 디바이스 테스트 안내
    echo ==============================
    echo.
    echo 실제 Android/iOS 디바이스에서 테스트하려면:
    echo 1. PC의 IP 주소를 확인하세요 (예: ipconfig 명령어)
    echo 2. lib/config/environment.dart의 baseUrlRealDevice를 수정하세요
    echo 3. 백엔드 서버가 해당 IP로 접근 가능한지 확인하세요
    echo 4. PC와 모바일이 같은 WiFi에 연결되어 있는지 확인하세요
    echo.
    echo 예시: 'baseUrlRealDevice': 'http://192.168.1.100:8080'
    echo.
    pause
)

echo.
echo %BUILD_MODE% 모드로 빌드 시작...

if "%BUILD_MODE%"=="release" (
    %BUILD_COMMAND%
    if errorlevel 1 (
        echo 릴리즈 빌드 실패!
        pause
        exit /b 1
    )
    
    echo.
    echo ===============================
    echo 릴리즈 빌드 완료!
    echo ===============================
    echo APK 파일 위치: build\app\outputs\flutter-apk\app-release.apk
    echo.
    echo 실제 디바이스에 설치하려면:
    echo 1. USB로 디바이스 연결
    echo 2. 개발자 옵션 활성화
    echo 3. USB 디버깅 허용
    echo 4. flutter install 명령어 실행
    echo.
) else (
    echo 연결된 디바이스 확인 중...
    flutter devices
    
    echo.
    echo 디바이스를 선택하고 앱을 실행합니다...
    %BUILD_COMMAND%
)

echo.
echo 완료!
pause