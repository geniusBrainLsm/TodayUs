# 앱 스토어 배포 완벽 가이드

## 🎯 배포 전략
1. **백엔드**: Railway에 API 서버 배포
2. **프론트엔드**: 모바일 앱 스토어에 배포 (Google Play Store + Apple App Store)

## 🏗️ 사전 준비사항

### 백엔드 API 서버
- [ ] Railway 배포 완료
- [ ] 프로덕션 URL 확정: `https://your-project.railway.app`
- [ ] 모든 API 엔드포인트 정상 작동 확인
- [ ] CORS 설정으로 모바일 앱 접근 허용

### 앱 개발 완료
- [ ] 모든 핵심 기능 구현 및 테스트 완료
- [ ] 프로덕션 환경에서 백엔드 API 연결 테스트
- [ ] 앱 아이콘, 스플래시 화면 디자인 완료
- [ ] 개인정보 처리방침, 이용약관 준비

## 📱 Google Play Store 배포

### 1단계: 개발자 계정 준비
- [ ] Google Play Console 계정 생성 ($25 일회성 등록비)
- [ ] 개발자 프로필 완성 (이름, 주소, 연락처)

### 2단계: 앱 서명 키 생성
```bash
# Android 스튜디오에서 또는 keytool 사용
keytool -genkey -v -keystore todayus-release-key.keystore -alias todayus -keyalg RSA -keysize 2048 -validity 10000
```

### 3단계: APK/AAB 빌드
```bash
cd frontend
# 프로덕션 환경으로 빌드
flutter build appbundle --release --dart-define=ENVIRONMENT=production
```

### 4단계: Play Console에서 앱 등록
1. **새 앱 만들기**
   - 앱 이름: "TodayUs - 커플 다이어리"
   - 기본 언어: 한국어
   - 앱 또는 게임: 앱
   - 무료 또는 유료: 무료

2. **스토어 설정**
   - 앱 카테고리: 라이프스타일
   - 콘텐츠 등급: 모든 연령
   - 타겟 연령층: 18세 이상

3. **스토어 리스팅**
   - 앱 이름: TodayUs - 커플 다이어리
   - 간단한 설명 (80자): 연인과 함께 쓰는 감정 일기, 소중한 추억을 기록하고 공유하세요
   - 자세한 설명: 
   ```
   💕 TodayUs와 함께 연인과의 특별한 순간들을 기록하세요!
   
   ✨ 주요 기능:
   • 감정 일기: 오늘의 기분과 함께 일기 작성
   • 커플 연결: 초대 코드로 연인과 일기 공유
   • 사진 업로드: 소중한 순간을 이미지로 기록
   • 댓글 기능: 서로의 일기에 따뜻한 댓글 남기기
   • 기념일 관리: 중요한 날짜들을 잊지 않도록 관리
   
   💝 TodayUs만의 특별함:
   • 간편한 소셜 로그인 (카카오, 구글)
   • 감정 분석을 통한 관계 인사이트
   • 개인정보 보호를 위한 안전한 데이터 관리
   
   사랑하는 사람과 함께 매일매일을 더욱 특별하게 만들어보세요! 💖
   ```

4. **그래픽 에셋**
   - [ ] 앱 아이콘 (512x512px)
   - [ ] 스크린샷 5-8개 (각 해상도별)
   - [ ] 피처 그래픽 (1024x500px, 선택사항)

### 5단계: AAB 업로드 및 검토 제출
- [ ] App Bundle (AAB) 업로드
- [ ] 앱 서명 활성화
- [ ] 출시 트랙 선택 (내부 테스트 → 공개 테스트 → 프로덕션)
- [ ] 검토 제출

## 🍎 Apple App Store 배포

### 1단계: Apple Developer Program 가입
- [ ] Apple Developer 계정 가입 ($99/년)
- [ ] 개발자 프로필 완성

### 2단계: iOS 빌드 (macOS 필요)
```bash
# macOS에서 실행
cd frontend
flutter build ios --release --dart-define=ENVIRONMENT=production
```

### 3단계: Xcode에서 Archive 생성
1. Xcode에서 `ios/Runner.xcworkspace` 열기
2. Product → Archive 선택
3. Archive Organizer에서 "Distribute App" 클릭
4. App Store Connect에 업로드

### 4단계: App Store Connect에서 앱 정보 설정
1. **앱 정보**
   - 이름: TodayUs - 커플 다이어리
   - 카테고리: 라이프스타일
   - SKU: com.todayus.app

2. **가격 및 사용 가능성**
   - 가격: 무료
   - 출시 국가: 대한민국 (또는 전 세계)

3. **앱 스토어 정보**
   - 스크린샷 (iPhone 6.7", 6.5", 5.5" 등)
   - 앱 미리보기 비디오 (선택사항)
   - 설명, 키워드, 지원 URL

### 5단계: 검토 제출
- [ ] 앱 심사 정보 작성
- [ ] 연락처 정보 제공
- [ ] 데모 계정 정보 (필요시)
- [ ] 검토 제출

## 🔧 빌드 자동화

### 환경별 빌드 명령어
```bash
# 개발 환경 (테스트용)
flutter build apk --debug

# 스테이징 환경 (내부 테스트용)
flutter build apk --release --dart-define=ENVIRONMENT=staging
flutter build appbundle --release --dart-define=ENVIRONMENT=staging

# 프로덕션 환경 (스토어 배포용)
flutter build apk --release --dart-define=ENVIRONMENT=production
flutter build appbundle --release --dart-define=ENVIRONMENT=production
flutter build ios --release --dart-define=ENVIRONMENT=production
```

### 자동 빌드 스크립트 사용
```bash
# Windows에서
cd frontend
.\build-for-stores.bat

# macOS에서
cd frontend  
chmod +x build-for-stores.sh
./build-for-stores.sh
```

## ⚠️ 주의사항 및 팁

### Google Play Store
- **검토 시간**: 보통 1-3일, 최대 7일
- **거부 사유**: 개인정보 처리방침 누락, 권한 사용 설명 부족
- **업데이트**: 기존 앱 업데이트는 더 빠른 검토

### Apple App Store
- **검토 시간**: 보통 1-7일
- **더 엄격한 심사**: UI/UX 품질, 앱 스토어 가이드라인 준수
- **거부 사유**: 충돌, 기능 불완전, 메타데이터 불일치

### 공통 주의사항
- **개인정보 처리방침** 필수
- **연령 등급** 정확히 설정
- **스크린샷**은 실제 앱 기능 반영
- **앱 설명**은 정확하고 이해하기 쉽게

## 📊 출시 후 관리

### 성과 모니터링
- [ ] Google Play Console / App Store Connect에서 다운로드 수, 평점 확인
- [ ] 사용자 리뷰 모니터링 및 응답
- [ ] 크래시 리포트 확인 및 수정

### 업데이트 관리
- [ ] 정기적인 앱 업데이트 (버그 수정, 새 기능)
- [ ] 백엔드 API 변경 시 앱 버전 호환성 확인
- [ ] 스토어 리스팅 최적화

## ✅ 최종 체크리스트

### 배포 전
- [ ] 백엔드 API 서버 Railway 배포 완료
- [ ] 프로덕션 환경에서 모든 기능 테스트 완료
- [ ] 앱 아이콘, 스크린샷, 설명 준비 완료
- [ ] 개발자 계정 등록 완료
- [ ] 개인정보 처리방침, 이용약관 준비

### 배포 후
- [ ] 두 스토어에서 앱 정상 배포 확인
- [ ] 실제 사용자 환경에서 기능 테스트
- [ ] 사용자 피드백 수집 계획 수립
- [ ] 향후 업데이트 로드맵 작성

성공적인 앱 스토어 출시를 위해 차근차근 진행해보세요! 🚀