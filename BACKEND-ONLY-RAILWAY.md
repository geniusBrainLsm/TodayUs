# 백엔드 전용 Railway 배포 가이드

모바일 앱 스토어 배포를 위한 백엔드 API 서버만 Railway에 배포하는 방법입니다.

## 🎯 배포 방법 (Root Directory 사용)

### 1단계: Railway 프로젝트 생성
1. **Railway 대시보드** 접속: https://railway.app/dashboard
2. **"New Project"** 클릭
3. **"Deploy from GitHub repo"** 선택
4. **TodayUs 레포지토리** 선택

### 2단계: Root Directory 설정 (핵심!)
1. 배포 후 Railway 프로젝트 설정으로 이동
2. **"Settings"** 탭 클릭
3. **"Source Repo"** 섹션에서:
   - **Root Directory**: `backend` 입력
   - **Watch Paths**: `backend/**` 입력
4. **Deploy Trigger**: `backend/**` 경로 변경 시에만 배포

### 3단계: 환경 변수 설정
**Variables** 탭에서 다음 환경 변수 추가:

```bash
# 필수 데이터베이스 설정
DATABASE_URL=postgresql://postgres:[PASSWORD]@[HOST]:[PORT]/railway
SPRING_PROFILES_ACTIVE=prod

# JWT 보안
JWT_SECRET=your-very-secure-jwt-secret-key-minimum-32-characters

# OAuth2 소셜 로그인
KAKAO_CLIENT_ID=e74f4850d8af7e2b2aec20f4faa636b3
KAKAO_CLIENT_SECRET=IOSjbcQZbcrB1NptoM85i9mHf1fRM5al

# AWS S3 이미지 업로드
AWS_ACCESS_KEY_ID=your-aws-access-key
AWS_SECRET_ACCESS_KEY=your-aws-secret-key
AWS_REGION=ap-northeast-2
AWS_S3_BUCKET=todayus

# CORS 설정 (모바일 앱용)
FRONTEND_URL=*

# OpenAI (선택사항)
OPENAI_API_KEY=your-openai-api-key
```

### 4단계: PostgreSQL 데이터베이스 추가
1. Railway 프로젝트에서 **"Add Service"** 클릭
2. **"PostgreSQL"** 선택
3. Railway가 자동으로 `DATABASE_URL` 환경 변수 생성
4. 백엔드가 자동으로 데이터베이스 연결

### 5단계: 배포 완료
1. **"Deploy"** 탭에서 배포 로그 확인
2. 빌드 및 시작 성공 확인
3. **Railway URL 확인**: `https://your-project.railway.app`

## ✅ 배포 확인 방법

### Health Check 테스트
```bash
curl https://your-project.railway.app/actuator/health
```
예상 응답:
```json
{"status":"UP"}
```

### API 엔드포인트 테스트
```bash
# CORS 테스트
curl https://your-project.railway.app/api/cors-test/simple

# 인증 테스트 (토큰 없이)
curl https://your-project.railway.app/api/auth/kakao
```

### Flutter 앱에서 테스트
1. `frontend/lib/config/environment.dart`에서:
   ```dart
   case Environment.production:
     return {
       'baseUrl': 'https://your-project.railway.app',
       ...
     };
   ```
2. 앱의 환경 설정에서 프로덕션 모드로 변경
3. CORS 테스트 실행

## 🚀 간단한 배포 프로세스

### 일회성 설정 (처음만)
1. Railway 프로젝트 생성
2. GitHub 레포 연결
3. **Root Directory = `backend`** 설정
4. PostgreSQL 서비스 추가
5. 환경 변수 설정

### 일상적인 배포 (이후)
```bash
# 백엔드 코드 수정 후
git add backend/
git commit -m "Update backend API"
git push origin main
# Railway가 자동으로 backend/ 변경사항만 감지하여 배포!
```

## 📱 모바일 앱 설정

### Android APK/AAB 빌드
```bash
cd frontend

# 프로덕션 환경으로 빌드
flutter build apk --release --dart-define=ENVIRONMENT=production
flutter build appbundle --release --dart-define=ENVIRONMENT=production
```

### iOS 빌드 (macOS 필요)
```bash
cd frontend

# 프로덕션 환경으로 빌드
flutter build ios --release --dart-define=ENVIRONMENT=production
```

### 환경 변수 자동 적용
`environment.dart`에서 빌드 시점에 환경 자동 결정:
```dart
static void initializeEnvironment() {
  const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
  
  switch (environment) {
    case 'production':
      setCurrent(Environment.production);
      break;
    case 'staging':
      setCurrent(Environment.staging);
      break;
    default:
      setCurrent(Environment.development);
  }
}
```

## 🔧 자동화 스크립트

### 백엔드 배포 스크립트
```batch
@echo off
echo 백엔드 Railway 배포...

cd backend
call gradlew.bat clean build
if errorlevel 1 (
    echo 빌드 실패!
    pause
    exit /b 1
)

cd ..
git add backend/
git commit -m "Backend update for Railway deployment"
git push origin main

echo Railway에서 자동 배포 시작됨!
echo 배포 상태: https://railway.app/dashboard
pause
```

### 모바일 앱 빌드 스크립트
```batch
@echo off
echo 모바일 앱 릴리즈 빌드...

cd frontend

echo Android APK 빌드...
flutter build apk --release --dart-define=ENVIRONMENT=production

echo Android App Bundle 빌드...
flutter build appbundle --release --dart-define=ENVIRONMENT=production

echo 빌드 완료!
echo APK: build\app\outputs\flutter-apk\app-release.apk
echo AAB: build\app\outputs\bundle\release\app-release.aab
pause
```

## 📋 체크리스트

### Railway 설정 완료
- [ ] GitHub 레포 연결
- [ ] Root Directory = `backend` 설정
- [ ] PostgreSQL 서비스 추가
- [ ] 모든 환경 변수 설정
- [ ] 배포 성공 및 Health check 통과

### 모바일 앱 준비
- [ ] 프로덕션 baseURL 설정
- [ ] 앱 아이콘 및 스플래시 설정
- [ ] Android/iOS 빌드 성공
- [ ] 스토어 개발자 계정 준비

### 최종 테스트
- [ ] 모바일 앱에서 Railway API 연결 성공
- [ ] 로그인 기능 정상 작동
- [ ] 이미지 업로드 정상 작동
- [ ] 모든 핵심 기능 테스트 완료

이 방법이 가장 깔끔하고 유지보수하기 좋습니다!