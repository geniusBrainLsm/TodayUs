# Flutter 프론트엔드 배포 옵션

Flutter 앱은 여러 플랫폼에 배포할 수 있습니다. 각 옵션의 장단점을 정리했습니다.

## 🚀 배포 옵션 비교

| 플랫폼 | 적합성 | 비용 | 난이도 | 특징 |
|-------|--------|------|--------|------|
| **모바일 앱 스토어** | ⭐⭐⭐⭐⭐ | 무료~유료 | 중간 | 네이티브 성능, 오프라인 지원 |
| **웹 (Vercel/Netlify)** | ⭐⭐⭐⭐ | 무료 | 쉬움 | 즉시 접근, URL 공유 가능 |
| **PWA** | ⭐⭐⭐⭐ | 무료 | 쉬움 | 앱 같은 웹, 설치 가능 |
| **데스크톱** | ⭐⭐⭐ | 무료 | 어려움 | Windows/Mac/Linux 지원 |

## 📱 1. 모바일 앱 스토어 (추천)

### Android (Google Play Store)
```bash
# APK/AAB 빌드
flutter build apk --release
flutter build appbundle --release

# 배포 준비
- Google Play Console 계정 ($25 일회성)
- 앱 서명 키 생성
- 스토어 리스팅 작성
- 검토 및 승인 (1-3일)
```

### iOS (Apple App Store)
```bash
# iOS 빌드 (macOS 필요)
flutter build ios --release

# 배포 준비
- Apple Developer Program ($99/년)
- Xcode 및 macOS 필요
- 앱 서명 인증서
- App Store Connect 업로드
- 검토 및 승인 (1-7일)
```

## 🌐 2. 웹 배포 (즉시 테스트용)

### Vercel 배포 (추천)
```bash
# 웹 빌드
cd frontend
flutter build web

# Vercel 배포
npm install -g vercel
vercel --cwd build/web

# 또는 GitHub 연동
- Vercel 대시보드에서 GitHub 레포 연결
- Build Command: "cd frontend && flutter build web"
- Output Directory: "frontend/build/web"
```

### Netlify 배포
```bash
# 빌드 설정
- Build command: "cd frontend && flutter build web"
- Publish directory: "frontend/build/web"
- Base directory: "frontend"

# 환경 변수 설정 (Netlify 대시보드)
FLUTTER_WEB=true
```

### Firebase Hosting
```bash
# Firebase 초기화
cd frontend
npm install -g firebase-tools
firebase init hosting

# 배포
flutter build web
firebase deploy --only hosting
```

## 📦 3. PWA (Progressive Web App)

Flutter 웹을 PWA로 배포하여 앱처럼 설치 가능하게 만들기:

### PWA 설정 강화
```dart
// frontend/web/manifest.json 업데이트
{
  "name": "TodayUs - 커플 다이어리",
  "short_name": "TodayUs",
  "description": "연인과 함께하는 감정 일기",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#667eea",
  "theme_color": "#764ba2",
  "icons": [
    {
      "src": "icons/Icon-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any maskable"
    },
    {
      "src": "icons/Icon-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "any maskable"
    }
  ]
}
```

### 오프라인 지원
```javascript
// frontend/web/sw.js (Service Worker)
self.addEventListener('fetch', function(event) {
  event.respondWith(
    caches.match(event.request)
      .then(function(response) {
        if (response) {
          return response;
        }
        return fetch(event.request);
      }
    )
  );
});
```

## 🛠️ 배포를 위한 환경 설정

### 1. 프로덕션 환경 변수 설정
```dart
// frontend/lib/config/environment.dart 수정
static void setProductionConfig() {
  _current = Environment.production;
  // 프로덕션 Railway URL 사용
}
```

### 2. 빌드 최적화
```yaml
# frontend/pubspec.yaml
flutter:
  assets:
    - assets/images/
  fonts:
    - family: Roboto
      fonts:
        - asset: fonts/Roboto-Regular.ttf

# 웹 빌드 최적화
flutter build web --release --tree-shake-icons
```

### 3. 도메인 및 HTTPS 설정
```bash
# 커스텀 도메인 (선택사항)
# Vercel/Netlify에서 도메인 연결
# SSL 인증서 자동 설정

# CORS 업데이트 (백엔드)
# 프론트엔드 도메인을 SecurityConfig.java에 추가
```

## 🎯 권장 배포 전략

### Phase 1: 개발 및 테스트
1. **웹 배포**: Vercel로 즉시 배포하여 테스트
2. **팀 공유**: URL을 통해 팀원들과 공유
3. **피드백 수집**: 웹에서 기본 기능 검증

### Phase 2: 베타 테스트
1. **Android APK**: 직접 설치 파일 제공
2. **TestFlight (iOS)**: Apple 베타 테스트 플랫폼
3. **PWA**: 웹에서 "홈 화면에 추가"로 앱 경험

### Phase 3: 정식 출시
1. **Google Play Store**: Android 사용자 대상
2. **Apple App Store**: iOS 사용자 대상
3. **웹 서비스**: 브라우저로 바로 접근

## 📋 배포 체크리스트

### 배포 전 준비
- [ ] 모든 환경에서 CORS 테스트 통과
- [ ] 프로덕션 환경 변수 설정
- [ ] Railway 백엔드 배포 완료
- [ ] API 엔드포인트 URL 업데이트
- [ ] 아이콘 및 이미지 최적화

### 웹 배포 (즉시 가능)
- [ ] `flutter build web` 성공
- [ ] Vercel/Netlify 배포 설정
- [ ] 커스텀 도메인 연결 (선택사항)
- [ ] PWA 기능 테스트

### 모바일 앱 배포 (장기)
- [ ] 개발자 계정 등록
- [ ] 앱 서명 키 생성
- [ ] 스토어 리스팅 준비
- [ ] 스크린샷 및 설명 작성
- [ ] 검토 제출

## ⚡ 빠른 시작 가이드

지금 당장 배포하고 싶다면:

```bash
# 1. 웹 빌드
cd frontend
flutter build web

# 2. Vercel 배포 (가장 빠름)
npx vercel --cwd build/web

# 3. URL 공유
# 배포 완료되면 URL로 즉시 접근 가능
```

이 방법으로 5분 내에 웹으로 배포하여 테스트할 수 있습니다!