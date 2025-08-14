# AWS S3 설정 가이드

TodayUs 애플리케이션에서 프로필 사진과 일기 사진을 업로드하기 위한 AWS S3 설정 방법을 안내합니다.

## 📋 목차
1. [AWS 계정 생성](#1-aws-계정-생성)
2. [S3 버킷 생성](#2-s3-버킷-생성)
3. [IAM 사용자 생성 및 권한 설정](#3-iam-사용자-생성-및-권한-설정)
4. [환경 변수 설정](#4-환경-변수-설정)
5. [버킷 정책 설정 (선택사항)](#5-버킷-정책-설정-선택사항)
6. [CORS 설정](#6-cors-설정)
7. [테스트](#7-테스트)

## 1. AWS 계정 생성

1. [AWS 콘솔](https://aws.amazon.com/)에 접속
2. **AWS 계정 만들기** 클릭
3. 이메일, 비밀번호, 계정 이름 입력
4. 신용카드 정보 입력 (Free Tier 사용 시에도 필요)
5. 전화번호 인증 완료
6. 지원 플랜 선택 (Basic 무료 플랜 권장)

## 2. S3 버킷 생성

### 2.1 S3 서비스 접속
1. AWS 콘솔에 로그인
2. 서비스 검색에서 **"S3"** 입력 후 선택
3. **"버킷 만들기"** 클릭

### 2.2 버킷 설정
```
버킷 이름: todayus-app-images (고유한 이름으로 변경 가능)
AWS 리전: 아시아 태평양 (서울) ap-northeast-2 (권장)
```

### 2.3 퍼블릭 액세스 설정
- **"모든 퍼블릭 액세스 차단"** 체크 해제
- 경고 메시지 확인 후 **"현재 설정으로 인해 이 버킷과 그 안에 포함된 객체가 퍼블릭 상태가 될 수 있음을 인정합니다"** 체크

### 2.4 버킷 생성 완료
- **"버킷 만들기"** 클릭
- 버킷이 생성되면 버킷 이름을 기록해 둡니다.

## 3. IAM 사용자 생성 및 권한 설정

### 3.1 IAM 서비스 접속
1. AWS 콘솔에서 **"IAM"** 서비스 선택
2. 좌측 메뉴에서 **"사용자"** 클릭
3. **"사용자 생성"** 클릭

### 3.2 사용자 생성
```
사용자 이름: todayus-s3-user (원하는 이름으로 변경 가능)
AWS 액세스 유형: 액세스 키 - 프로그래밍 방식 액세스
```

### 3.3 권한 설정
1. **"직접 정책 연결"** 선택
2. **"정책 생성"** 클릭 (새 탭에서 열림)

#### 정책 JSON 설정:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:PutObjectAcl",
                "s3:GetObject",
                "s3:DeleteObject"
            ],
            "Resource": "arn:aws:s3:::todayus-app-images/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": "arn:aws:s3:::todayus-app-images"
        }
    ]
}
```

3. **정책 이름**: `TodayUsS3Policy`
4. **"정책 생성"** 클릭
5. 원래 탭으로 돌아가서 새로 만든 정책을 선택
6. **"다음"** → **"사용자 생성"** 클릭

### 3.4 액세스 키 생성
1. 생성된 사용자 클릭
2. **"보안 자격 증명"** 탭 선택
3. **"액세스 키 만들기"** 클릭
4. **"애플리케이션에서 실행되는 코드"** 선택
5. **"위의 권장 사항을 이해했으며 액세스 키 생성을 계속하려고 합니다"** 체크
6. **"다음"** → **"액세스 키 만들기"** 클릭

⚠️ **중요**: 액세스 키와 시크릿 액세스 키를 안전한 곳에 저장하세요. 다시 볼 수 없습니다!

## 4. 환경 변수 설정

### 4.1 백엔드 환경 변수
프로젝트 루트 디렉토리에 `.env` 파일을 생성하거나 시스템 환경 변수로 설정:

```bash
# AWS S3 설정
AWS_ACCESS_KEY=AKIA...your_access_key
AWS_SECRET_KEY=your_secret_access_key
AWS_REGION=ap-northeast-2
AWS_S3_BUCKET=todayus-app-images

# S3 경로 설정 (선택사항)
AWS_S3_PROFILE_PATH=profile-images/
AWS_S3_DIARY_PATH=diary-images/
```

### 4.2 운영 환경 설정
운영 서버에서는 환경 변수로 직접 설정:

**Linux/macOS:**
```bash
export AWS_ACCESS_KEY=your_access_key
export AWS_SECRET_KEY=your_secret_access_key
export AWS_REGION=ap-northeast-2
export AWS_S3_BUCKET=todayus-app-images
```

**Windows:**
```cmd
set AWS_ACCESS_KEY=your_access_key
set AWS_SECRET_KEY=your_secret_access_key
set AWS_REGION=ap-northeast-2
set AWS_S3_BUCKET=todayus-app-images
```

## 5. 버킷 정책 설정 (선택사항)

S3 버킷에서 업로드된 이미지에 대한 퍼블릭 읽기 권한을 설정:

1. S3 콘솔에서 생성한 버킷 선택
2. **"권한"** 탭 클릭
3. **"버킷 정책"** 섹션에서 **"편집"** 클릭
4. 다음 JSON 입력:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::todayus-app-images/*"
        }
    ]
}
```

5. **"변경 사항 저장"** 클릭

## 6. CORS 설정

업로드된 이미지를 웹에서 표시하기 위한 CORS 설정:

1. S3 버킷의 **"권한"** 탭 선택
2. **"CORS(Cross-Origin Resource Sharing)"** 섹션에서 **"편집"** 클릭
3. 다음 JSON 입력:

```json
[
    {
        "AllowedHeaders": ["*"],
        "AllowedMethods": ["GET", "PUT", "POST", "DELETE"],
        "AllowedOrigins": ["*"],
        "ExposeHeaders": []
    }
]
```

4. **"변경 사항 저장"** 클릭

## 7. 테스트

### 7.1 설정 확인
애플리케이션을 실행하고 다음을 테스트:

1. **프로필 사진 업로드**
   - 프로필 화면에서 사진 선택
   - 카메라/갤러리에서 이미지 선택
   - 업로드 성공 메시지 확인

2. **일기 사진 업로드**
   - 일기 작성 화면에서 사진 추가
   - 카메라/갤러리에서 이미지 선택
   - 일기 저장 후 이미지 표시 확인

### 7.2 S3 콘솔에서 확인
1. S3 버킷 내용 확인:
   ```
   todayus-app-images/
   ├── profile-images/
   │   └── user_123_20241214_abc12345.jpg
   └── diary-images/
       └── diary_456_user_123_20241214_def67890.jpg
   ```

### 7.3 로그 확인
애플리케이션 로그에서 다음 메시지 확인:
```
Profile image uploaded successfully for user 123: https://todayus-app-images.s3.ap-northeast-2.amazonaws.com/profile-images/user_123_...jpg
```

## 🚀 완료!

이제 TodayUs 애플리케이션에서 S3를 통해 이미지 업로드가 가능합니다.

## 💡 추가 팁

### 비용 최적화
- **S3 Intelligent-Tiering**: 자주 접근하지 않는 오래된 이미지는 자동으로 저렴한 스토리지 클래스로 이동
- **라이프사이클 정책**: 일정 기간 후 이미지 자동 삭제 또는 아카이브

### 보안 강화
- **VPC 엔드포인트**: EC2에서 S3로의 트래픽을 인터넷을 거치지 않고 AWS 네트워크 내부에서 처리
- **액세스 로깅**: S3 액세스 로그 활성화
- **암호화**: S3 서버 측 암호화 (SSE-S3) 활성화

### 성능 최적화
- **CloudFront**: CDN을 통한 이미지 배포로 로딩 속도 향상
- **압축**: 업로드 전 이미지 압축 처리

## ❗ 주의사항

1. **AWS 계정 보안**
   - 루트 계정 대신 IAM 사용자 사용
   - MFA (다중 인증) 활성화 권장

2. **비용 관리**
   - AWS Free Tier 한도 확인
   - S3 스토리지 및 요청 비용 모니터링

3. **액세스 키 관리**
   - 액세스 키를 코드에 하드코딩하지 말 것
   - 정기적으로 액세스 키 교체
   - 사용하지 않는 액세스 키는 즉시 삭제

4. **데이터 백업**
   - 중요한 이미지는 별도 백업 계획 수립
   - 버전 관리 활성화 고려