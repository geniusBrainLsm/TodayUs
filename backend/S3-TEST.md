# S3 연동 설정 완료 ✅

## 설정된 환경 변수
```
AWS_ACCESS_KEY=AKIATTI7CMBD6GTJ5WMX
AWS_SECRET_KEY=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
AWS_REGION=ap-northeast-2
AWS_S3_BUCKET=todayus
AWS_S3_PROFILE_PATH=profile-images/
AWS_S3_DIARY_PATH=diary-images/
```

## 백엔드 설정 업데이트 완료
- ✅ `.env` 파일 생성 및 AWS 자격증명 설정
- ✅ `application.yml` 버킷명 `todayus`로 수정
- ✅ 기본 리전을 `ap-northeast-2`로 설정

## S3 버킷 구조
```
todayus/
├── profile-images/
│   └── (프로필 사진들이 저장됨)
└── diary-images/
    └── (일기 사진들이 저장됨)
```

## 테스트 방법
1. 백엔드 서버 실행
2. 프로필 화면에서 사진 업로드 테스트
3. 일기 작성에서 사진 업로드 테스트
4. AWS S3 콘솔에서 파일 업로드 확인

## 주의사항
- AWS 자격증명이 `.env` 파일에 저장되어 있으므로 `.gitignore`에 `.env` 추가 필요
- 실제 운영 환경에서는 환경변수로 직접 설정 권장

## 다음 단계
1. 백엔드 서버 시작
2. 프론트엔드 앱에서 이미지 업로드 기능 테스트
3. S3 콘솔에서 업로드된 파일 확인