# 백엔드 빌드 및 실행 가이드

## 해결된 문제들
✅ CoupleRepository findByUser1OrUser2 메서드 추가  
✅ InviteCodeDto CreateRequest 중복 생성자 제거  
✅ CoupleController Map.of 타입 추론 문제 수정  
✅ CoupleService UserDto import 추가  

## 빌드 및 실행 방법

### 1. IntelliJ IDEA 사용 (권장)
1. IntelliJ에서 `backend` 폴더만 열기
2. Gradle 프로젝트로 인식되면 자동으로 dependency 다운로드
3. `src/main/java/com/todayus/TodayUsApplication.java` 실행

### 2. 명령줄 사용
```bash
cd backend

# Windows
set JAVA_HOME=C:\Program Files\Java\jdk-17
gradlew.bat clean build
gradlew.bat bootRun

# Linux/Mac  
export JAVA_HOME=/path/to/jdk-17
./gradlew clean build
./gradlew bootRun
```

### 3. 배치 파일 사용 (Windows)
```bash
cd backend
run.bat            # 컴파일 + 실행
compile-test.bat    # 컴파일만 테스트
simple-test.bat     # 기본 Java 테스트
```

## 전제 조건
- Java 17 설치
- PostgreSQL 실행 중 (Docker: `docker-compose up -d`)
- 포트 8080 사용 가능

## 트러블슈팅
1. **JAVA_HOME 문제**: 환경변수에서 올바른 JDK 17 경로 설정
2. **Gradle Wrapper 문제**: `gradle/wrapper/` 폴더와 파일들 존재 확인
3. **데이터베이스 연결 실패**: PostgreSQL 실행 여부 확인
4. **포트 충돌**: 8080 포트 사용 중인 프로세스 종료

## 현재 상태
- 모든 알려진 컴파일 오류 수정 완료
- IntelliJ에서 실행 권장 (자동 dependency 관리)
- 명령줄 빌드는 환경 설정에 따라 다를 수 있음