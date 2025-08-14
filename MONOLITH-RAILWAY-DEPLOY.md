# 모노리식 구조 Railway 배포 가이드

## 📁 현재 프로젝트 구조
```
TodayUs/
├── frontend/          # Flutter 앱
│   ├── lib/
│   ├── pubspec.yaml
│   └── ...
├── backend/           # Spring Boot API
│   ├── src/
│   ├── build.gradle
│   └── ...
├── Dockerfile         # 백엔드 전용 Docker 설정
├── .dockerignore
└── nixpacks.toml      # Nixpacks 설정 (대안)
```

## 🚀 배포 방법 (3가지 옵션)

### 옵션 1: Docker 사용 (추천)
가장 안정적이고 예측 가능한 방법

#### 1.1 Railway 프로젝트 설정
1. Railway 대시보드에서 "New Project" 클릭
2. "Deploy from GitHub repo" 선택
3. TodayUs 레포지토리 선택
4. **Root Directory 설정하지 말고** 그대로 두기
5. Railway가 루트의 `Dockerfile`을 자동 감지

#### 1.2 환경 변수 설정
Railway Variables 탭에서 설정:
```bash
# 필수 환경 변수
DATABASE_URL=postgresql://...  # Railway PostgreSQL 연결
JWT_SECRET=your-jwt-secret
KAKAO_CLIENT_ID=your-kakao-id
KAKAO_CLIENT_SECRET=your-kakao-secret
AWS_ACCESS_KEY_ID=your-s3-key
AWS_SECRET_ACCESS_KEY=your-s3-secret
AWS_REGION=ap-northeast-2
AWS_S3_BUCKET=todayus
SPRING_PROFILES_ACTIVE=prod
```

### 옵션 2: Nixpacks 사용
Railway의 기본 빌드 시스템 사용

#### 2.1 루트에 nixpacks.toml 설정 (이미 생성됨)
```toml
[variables]
NIXPACKS_JAVA_VERSION = "17"

[phases.build]
cmd = "cd backend && chmod +x gradlew && ./gradlew clean build -x test"

[phases.start]
cmd = "cd backend && java -jar build/libs/*.jar"
```

#### 2.2 Railway 설정
- Railway가 자동으로 nixpacks.toml 감지
- 백엔드만 빌드 및 배포

### 옵션 3: Root Directory 지정
백엔드 디렉토리만 배포

#### 3.1 Railway 설정
1. Railway 프로젝트 설정에서
2. "Settings" > "Environment" 
3. **Root Directory**: `backend`
4. Railway가 backend/ 내의 파일들만 사용

## 📋 배포 단계별 가이드

### 1단계: 사전 준비
```bash
# 로컬에서 백엔드 빌드 테스트
cd backend
./gradlew clean build

# Docker 빌드 테스트 (선택사항)
cd ..
docker build -t todayus-backend .
docker run -p 8080:8080 todayus-backend
```

### 2단계: GitHub 푸시
```bash
git add .
git commit -m "Add Railway deployment config"
git push origin main
```

### 3단계: Railway 배포
1. **Railway 대시보드** 접속
2. **"New Project"** 클릭
3. **"Deploy from GitHub repo"** 선택
4. **TodayUs 레포지토리** 선택
5. Railway가 자동으로 Dockerfile 또는 nixpacks.toml 감지
6. 배포 시작

### 4단계: 환경 변수 설정
Railway Variables 탭에서 모든 환경 변수 추가

### 5단계: 데이터베이스 연결
1. **"Add Service"** > **"PostgreSQL"** 추가
2. Railway가 자동으로 DATABASE_URL 생성
3. 백엔드가 자동으로 데이터베이스 연결

## ⚙️ 설정 파일 설명

### Dockerfile
- **Multi-stage build**: 빌드와 런타임 분리
- **백엔드만 빌드**: frontend/ 디렉토리 무시
- **최적화**: 레이어 캐싱으로 빌드 시간 단축

### .dockerignore
- **프론트엔드 제외**: Docker 이미지 크기 최소화
- **빌드 결과물 제외**: 새로 빌드하므로 불필요
- **IDE 파일 제외**: 배포에 불필요한 파일들

### nixpacks.toml
- **Java 17 지정**: 정확한 Java 버전 사용
- **백엔드 디렉토리**: cd backend로 경로 변경
- **Gradle 권한**: chmod +x gradlew로 실행 권한 부여

## 🔍 배포 후 확인사항

### 1. 배포 로그 확인
Railway 대시보드의 "Deployments" 탭에서:
- ✅ 빌드 성공
- ✅ 컨테이너 시작
- ✅ Health check 통과

### 2. API 테스트
```bash
# Health check
curl https://your-app.railway.app/actuator/health

# CORS 테스트
curl https://your-app.railway.app/api/cors-test/simple
```

### 3. Flutter 앱에서 테스트
앱의 환경 설정에서 Railway URL로 변경 후 CORS 테스트 실행

## 🚨 일반적인 문제 해결

### 빌드 실패
```bash
# 원인: Gradle 권한 문제
# 해결: nixpacks.toml에 chmod +x gradlew 추가

# 원인: Java 버전 불일치
# 해결: NIXPACKS_JAVA_VERSION = "17" 확인
```

### 시작 실패
```bash
# 원인: JAR 파일 경로 오류
# 해결: build/libs/*.jar 경로 확인

# 원인: 환경 변수 누락
# 해결: DATABASE_URL, JWT_SECRET 등 필수 변수 확인
```

### 데이터베이스 연결 실패
```bash
# 원인: DATABASE_URL 형식 오류
# 해결: Railway PostgreSQL 서비스의 CONNECTION_URL 사용
```

## 📊 비용 최적화

### Railway 무료 플랜 한도
- **실행 시간**: 월 500시간
- **메모리**: 512MB
- **대역폭**: 100GB

### 최적화 방법
1. **슬립 모드**: 비활성 시 자동 슬립
2. **메모리 제한**: JVM 힙 크기 조정
3. **불필요한 의존성 제거**

## 🔄 CI/CD 자동화

### GitHub Actions (선택사항)
Railway는 GitHub 푸시 시 자동 배포되므로 별도 CI/CD 불필요

### 수동 재배포
Railway 대시보드에서 "Redeploy" 버튼 클릭

## ✅ 체크리스트

배포 전:
- [ ] 로컬에서 백엔드 빌드 성공
- [ ] Dockerfile 또는 nixpacks.toml 설정 완료
- [ ] .dockerignore 파일 확인
- [ ] 필요한 환경 변수 목록 준비

배포 후:
- [ ] Railway 배포 성공
- [ ] Health check 통과
- [ ] 환경 변수 모두 설정
- [ ] 데이터베이스 연결 확인
- [ ] CORS 테스트 통과
- [ ] Flutter 앱에서 API 호출 성공