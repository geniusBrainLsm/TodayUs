# Railway 환경 변수 설정 가이드

## 필수 환경 변수

Railway 대시보드에서 다음 환경 변수들을 설정해야 합니다:

### 1. 데이터베이스 설정
```bash
# PostgreSQL 데이터베이스 (Railway에서 자동 생성)
DATABASE_URL=postgresql://username:password@host:port/database
PGHOST=host
PGPORT=5432
PGDATABASE=railway
PGUSER=postgres
PGPASSWORD=your-password

# 애플리케이션에서 사용할 DB 설정
DB_USERNAME=postgres
DB_PASSWORD=your-password
DB_HOST=host
DB_PORT=5432
DB_NAME=railway
```

### 2. JWT 보안 설정
```bash
# JWT 토큰 시크릿 키 (안전한 랜덤 문자열)
JWT_SECRET=your-very-secure-jwt-secret-key-minimum-32-characters
```

### 3. OAuth2 소셜 로그인 설정
```bash
# 카카오 OAuth2
KAKAO_CLIENT_ID=e74f4850d8af7e2b2aec20f4faa636b3
KAKAO_CLIENT_SECRET=IOSjbcQZbcrB1NptoM85i9mHf1fRM5al

# Google OAuth2 (필요시)
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
```

### 4. AWS S3 설정 (이미지 업로드용)
```bash
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_REGION=ap-northeast-2
AWS_S3_BUCKET=todayus
```

### 5. OpenAI API 설정 (선택사항)
```bash
OPENAI_API_KEY=your-openai-api-key
```

### 6. 애플리케이션 설정
```bash
# 배포 환경
SPRING_PROFILES_ACTIVE=prod

# CORS 설정 (프론트엔드 도메인)
FRONTEND_URL=https://your-frontend-domain.com

# 베이스 URL (Railway에서 자동 설정)
BASE_URL=https://todayus-backend-production.up.railway.app

# 포트 설정 (Railway에서 자동 설정하지만 명시적으로 설정 가능)
PORT=8080
```

### 7. CORS 테스트
배포 후 CORS 설정이 정상 작동하는지 테스트:

```bash
# GET 요청 테스트
curl -H "Origin: https://your-frontend-domain.com" \
     -H "Access-Control-Request-Method: GET" \
     -H "Access-Control-Request-Headers: X-Requested-With" \
     -X OPTIONS \
     https://todayus-backend-production.up.railway.app/api/cors-test/simple

# 또는 Flutter 앱에서 환경설정 > CORS 테스트 실행
```

## 설정 방법

1. **Railway 대시보드 접속**
   - https://railway.app/dashboard
   - 프로젝트 선택

2. **Variables 탭 클릭**
   - 프로젝트 페이지에서 "Variables" 탭을 클릭

3. **환경 변수 추가**
   - "New Variable" 버튼 클릭
   - 위의 환경 변수들을 하나씩 추가

4. **배포 재시작**
   - 환경 변수 변경 후 자동으로 재배포됨
   - 또는 "Deploy" 탭에서 수동으로 재배포 가능

## 보안 주의사항

- JWT_SECRET은 최소 32자 이상의 안전한 랜덤 문자열 사용
- API 키들은 절대 코드에 하드코딩하지 말 것
- 프로덕션 환경에서는 디버그 모드 비활성화

## 데이터베이스 초기화

첫 배포 시 데이터베이스 테이블이 자동으로 생성됩니다:
- Spring Boot JPA가 자동으로 테이블 생성
- application-prod.yml에서 DDL 설정 확인

## 트러블슈팅

### 환경 변수 적용 안됨
- Railway 배포 로그 확인
- 변수 이름 오타 확인
- 재배포 필요할 수 있음

### 데이터베이스 연결 실패
- DATABASE_URL 형식 확인
- PostgreSQL 서비스 실행 상태 확인
- 네트워크 연결 문제 확인

### OAuth2 로그인 실패
- 카카오 개발자 콘솔에서 Redirect URI 업데이트 필요
- https://todayus-backend-production.up.railway.app/api/auth/kakao/callback