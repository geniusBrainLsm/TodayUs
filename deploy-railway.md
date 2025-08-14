# Railway 배포 가이드

## 현재 배포 상태
- **배포 URL**: https://todayus-backend-production.up.railway.app
- **상태**: 설정 완료, 환경 변수 추가 필요

## 1. Railway 계정 및 프로젝트 설정

### Railway 계정 생성
1. https://railway.app 에서 GitHub 계정으로 로그인
2. 새 프로젝트 생성 (또는 기존 프로젝트 사용)

### PostgreSQL 데이터베이스 추가
1. Railway 대시보드에서 "Add Service" 클릭
2. "Database" → "PostgreSQL" 선택
3. 자동으로 데이터베이스 인스턴스 생성됨

## 2. 환경 변수 설정

Railway 프로젝트의 "Variables" 탭에서 다음 환경 변수들을 설정:

```bash
# 데이터베이스 (PostgreSQL 서비스에서 자동 설정됨)
DATABASE_URL=postgresql://username:password@host:port/database
DB_USERNAME=postgres
DB_PASSWORD=your-password

# JWT 설정
JWT_SECRET=your-very-secure-jwt-secret-key-here

# OAuth2 설정
KAKAO_CLIENT_ID=e74f4850d8af7e2b2aec20f4faa636b3
KAKAO_CLIENT_SECRET=IOSjbcQZbcrB1NptoM85i9mHf1fRM5al
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret

# OpenAI 설정 (선택사항)
OPENAI_API_KEY=your-openai-api-key

# 앱 설정
BASE_URL=https://your-railway-app.railway.app
FRONTEND_URL=https://your-frontend-url.com
```

## 3. 배포 명령어

### GitHub 연동으로 자동 배포
1. Railway에서 "Deploy from GitHub repo" 선택
2. TodayUs 레포지토리 선택
3. 루트 디렉토리를 `/backend`로 설정
4. 자동으로 빌드 및 배포 시작

### CLI로 배포 (선택사항)
```bash
# Railway CLI 설치
npm install -g @railway/cli

# 로그인
railway login

# 프로젝트 연결
railway link

# 배포
railway up
```

## 4. 배포 확인

### 헬스체크 확인
```
GET https://your-app.railway.app/actuator/health
```

### API 테스트
```
GET https://your-app.railway.app/api/auth/kakao/test
```

## 5. 카카오 개발자 콘솔 설정 업데이트

Railway 배포 후에는 카카오 개발자 콘솔에서 Redirect URI를 업데이트해야 합니다:

```
https://your-app.railway.app/api/auth/kakao/callback
```

## 6. Flutter 앱 설정 업데이트

Flutter 앱의 API 엔드포인트를 Railway URL로 업데이트:

```dart
// frontend/lib/config/environment.dart
static const String productionBaseUrl = 'https://your-app.railway.app';
```

## 트러블슈팅

### 빌드 실패 시
- Java 17이 설정되어 있는지 확인
- Gradle 빌드가 로컬에서 성공하는지 확인

### 데이터베이스 연결 실패 시
- DATABASE_URL 환경 변수가 올바른지 확인
- PostgreSQL 서비스가 실행 중인지 확인

### 메모리 부족 시
- Railway의 메모리 제한 확인 (기본 512MB)
- 필요시 플랜 업그레이드