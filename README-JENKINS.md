# Jenkins CI/CD 구성

## 파이프라인 구조

### 1. 루트 `/Jenkinsfile` (메인 백엔드 배포)
- **용도**: 프로덕션 백엔드 배포 (RDS 연결)
- **방식**: 네이티브 Docker 명령어 사용
- **특징**:
  - Gradle 빌드
  - Docker 이미지 생성
  - RDS 데이터베이스 연결
  - 헬스체크 포함

### 2. `/backend/Jenkinsfile` (로컬/개발 배포)
- **용도**: 개발환경 배포
- **방식**: Docker Compose 스크립트 호출
- **특징**:
  - `scripts/deploy.sh` 실행
  - 전체 스택 배포 (DB 포함)

### 3. `/frontend/Jenkinsfile` (프론트엔드 빌드)
- **용도**: Flutter 앱 빌드 및 배포
- **특징**:
  - Web 빌드
  - APK 생성
  - Nginx 배포

## 사용 가이드

### 프로덕션 배포
```bash
# 루트 Jenkinsfile 사용
# Jenkins에서 프로젝트 루트를 소스로 설정
```

### 개발환경 배포
```bash
# backend/Jenkinsfile 사용
# Jenkins에서 backend 폴더를 소스로 설정
```

### 프론트엔드 배포
```bash
# frontend/Jenkinsfile 사용
# Jenkins에서 frontend 폴더를 소스로 설정
```

## 문제 해결

### 경로 오류 수정 완료
- ❌ `cd /workspace` (잘못된 경로)
- ✅ 현재 작업 디렉토리에서 직접 실행

### Docker 요구사항
- 프로덕션: Docker Engine
- 개발환경: Docker + Docker Compose