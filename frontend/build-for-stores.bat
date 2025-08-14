@echo off
echo ==========================================
echo TodayUs 앱 스토어 배포용 빌드
echo ==========================================

cd /d "%~dp0"

echo.
echo 빌드 환경을 선택하세요:
echo 1. 스테이징 환경 (테스트용)
echo 2. 프로덕션 환경 (스토어 배포용)
set /p BUILD_ENV="환경 선택 (1-2): "

if "%BUILD_ENV%"=="1" (
    set ENVIRONMENT=staging
    echo 스테이징 환경으로 빌드합니다.
) else (
    set ENVIRONMENT=production
    echo 프로덕션 환경으로 빌드합니다.
)

echo.
echo 빌드할 플랫폼을 선택하세요:
echo 1. Android만
echo 2. iOS만 (macOS 필요)
echo 3. 둘 다
set /p PLATFORM="플랫폼 선택 (1-3): "

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
    echo 코드 분석 중 경고/오류 발견!
    echo 계속 진행하시겠습니까? (y/n)
    set /p CONTINUE=""
    if /i not "%CONTINUE%"=="y" (
        pause
        exit /b 1
    )
)

if "%PLATFORM%"=="1" goto BUILD_ANDROID
if "%PLATFORM%"=="2" goto BUILD_IOS  
if "%PLATFORM%"=="3" goto BUILD_BOTH

echo 잘못된 선택입니다.
pause
exit /b 1

:BUILD_ANDROID
echo.
echo ========================================
echo Android 빌드 시작
echo ========================================

echo 1. APK 빌드 (직접 설치용)...
flutter build apk --release --dart-define=ENVIRONMENT=%ENVIRONMENT%
if errorlevel 1 (
    echo APK 빌드 실패!
    pause
    exit /b 1
)

echo 2. App Bundle 빌드 (Play Store용)...
flutter build appbundle --release --dart-define=ENVIRONMENT=%ENVIRONMENT%
if errorlevel 1 (
    echo App Bundle 빌드 실패!
    pause
    exit /b 1
)

echo.
echo ✅ Android 빌드 완료!
echo APK 파일: build\app\outputs\flutter-apk\app-release.apk
echo AAB 파일: build\app\outputs\bundle\release\app-release.aab
echo.
goto END

:BUILD_IOS
echo.
echo ========================================
echo iOS 빌드 시작
echo ========================================

echo macOS에서만 iOS 빌드가 가능합니다.
echo 현재 Windows 환경에서는 iOS 빌드를 할 수 없습니다.
echo.
echo macOS에서 다음 명령어를 실행하세요:
echo flutter build ios --release --dart-define=ENVIRONMENT=%ENVIRONMENT%
echo.
pause
goto END

:BUILD_BOTH
echo.
echo ========================================
echo Android + iOS 빌드
echo ========================================

call :BUILD_ANDROID_ONLY
if errorlevel 1 goto ERROR

echo.
echo iOS는 macOS에서 별도로 빌드해야 합니다.
echo macOS에서 다음 명령어를 실행하세요:
echo flutter build ios --release --dart-define=ENVIRONMENT=%ENVIRONMENT%
echo.
goto END

:BUILD_ANDROID_ONLY
echo Android APK 빌드...
flutter build apk --release --dart-define=ENVIRONMENT=%ENVIRONMENT%
if errorlevel 1 exit /b 1

echo Android App Bundle 빌드...
flutter build appbundle --release --dart-define=ENVIRONMENT=%ENVIRONMENT%
if errorlevel 1 exit /b 1

echo ✅ Android 빌드 완료!
exit /b 0

:ERROR
echo.
echo ❌ 빌드 실패!
echo 오류를 확인하고 다시 시도하세요.
pause
exit /b 1

:END
echo.
echo ==========================================
echo 앱 스토어 배포 준비 완료!
echo ==========================================
echo.
echo 📱 다음 단계:
echo.
echo [Google Play Store 배포]
echo 1. Google Play Console 접속
echo 2. AAB 파일 업로드: build\app\outputs\bundle\release\app-release.aab
echo 3. 스토어 리스팅 작성
echo 4. 검토 제출
echo.
echo [Apple App Store 배포]
echo 1. macOS에서 iOS 빌드 완료
echo 2. Xcode에서 Archive 생성
echo 3. App Store Connect 업로드
echo 4. 스토어 리스팅 작성
echo 5. 검토 제출
echo.
echo [테스트 배포]
echo - APK 직접 설치: build\app\outputs\flutter-apk\app-release.apk
echo - Firebase App Distribution 또는 TestFlight 사용
echo.
pause