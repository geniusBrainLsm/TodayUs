# 🔧 TodayUs API 관리 시스템

## 📁 **파일 구조**

```
frontend/lib/
├── config/
│   ├── environment.dart          # 환경별 설정 관리
│   └── api_endpoints.dart        # 모든 API 엔드포인트 중앙 관리
├── services/
│   ├── api_service.dart          # HTTP 클라이언트 및 공통 기능
│   ├── auth_service.dart         # 인증 관련 서비스
│   ├── couple_message_service.dart  # 대신 전달하기 서비스
│   └── [기타 서비스들...]
└── main.dart                     # 환경 초기화
```

## 🌍 **환경 관리 (environment.dart)**

### **지원 환경**
- `Development`: 로컬 개발 환경
- `Staging`: 스테이징 환경  
- `Production`: 운영 환경

### **환경별 설정**
```dart
// 개발 환경
'baseUrl': 'http://localhost:8080'
'enableLogging': true
'apiTimeout': 30000ms

// 스테이징 환경  
'baseUrl': 'https://staging-api.todayus.com'
'enableLogging': true
'apiTimeout': 15000ms

// 운영 환경
'baseUrl': 'https://api.todayus.com'
'enableLogging': false
'apiTimeout': 10000ms
```

## 🎯 **API 엔드포인트 관리 (api_endpoints.dart)**

### **인증 관련**
- `kakaoLogin`: 카카오 OAuth2 로그인
- `naverLogin`: 네이버 OAuth2 로그인
- `googleLogin`: 구글 OAuth2 로그인
- `authMe`: 현재 사용자 정보 조회
- `authValidate`: 토큰 유효성 검증

### **사용자 관리**
- `users`: 사용자 CRUD
- `checkNikname`: 닉네임 중복 확인
- `setNickname`: 닉네임 설정
- `getNickname`: 닉네임 조회

### **커플 관리**
- `couples`: 커플 정보 관리
- `generateInviteCode`: 초대 코드 생성
- `connectWithCode`: 초대 코드로 연결
- `validateInviteCode(code)`: 초대 코드 검증

### **일기 관리**
- `diaries`: 일기 CRUD
- `recentDiaries`: 최근 일기 조회
- `emotionStats`: 감정 통계
- `weeklyEmotionSummary`: 주간 감정 요약

### **대신 전달하기**
- `coupleMessages`: 메시지 CRUD
- `messageForPopup`: 팝업용 메시지 조회
- `weeklyUsage`: 주간 사용량 확인
- `markAsDelivered(id)`: 전달 완료 처리
- `markAsRead(id)`: 읽음 처리

### **유틸리티 메서드**
```dart
// 페이지네이션
ApiEndpoints.withPagination('/api/diaries', page: 1, size: 10)

// 날짜 범위
ApiEndpoints.withDateRange('/api/stats', startDate: date1, endDate: date2)

// 검색
ApiEndpoints.withSearch('/api/diaries', '키워드')

// 정렬
ApiEndpoints.withSort('/api/diaries', 'createdAt', ascending: false)

// 복합 파라미터
ApiEndpoints.withParams('/api/diaries', {'status': 'active', 'limit': 20})
```

## 🔧 **고급 HTTP 클라이언트 (api_service.dart)**

### **기본 HTTP 메서드**
- `GET`: `ApiService.get(endpoint)`
- `POST`: `ApiService.post(endpoint, body)`
- `PUT`: `ApiService.put(endpoint, body)`
- `DELETE`: `ApiService.delete(endpoint)`
- `PATCH`: `ApiService.patch(endpoint, body)`

### **파일 업로드**
```dart
await ApiService.uploadFile(
  ApiEndpoints.uploadImage,
  '/path/to/image.jpg',
  'imageFile',
  additionalFields: {'description': '프로필 이미지'},
);
```

### **자동 재시도**
```dart
final response = await ApiService.getWithRetry(
  ApiEndpoints.diaries,
  maxRetries: 3,
  retryDelay: Duration(seconds: 2),
);
```

### **오류 처리**
- `UnauthorizedException`: 401 인증 오류
- `ForbiddenException`: 403 권한 오류
- `NotFoundException`: 404 리소스 없음
- `TooManyRequestsException`: 429 요청 한도 초과
- `InternalServerErrorException`: 500 서버 오류

## 🎨 **사용 예시**

### **1. 환경 설정**
```dart
// main.dart
void main() {
  EnvironmentConfig.setCurrent(Environment.production);
  runApp(MyApp());
}
```

### **2. API 호출**
```dart
// 기존 방식 (❌)
final response = await http.get(
  Uri.parse('http://localhost:8080/api/couple-messages'),
  headers: {'Authorization': 'Bearer $token'},
);

// 새로운 방식 (✅)
final response = await ApiService.get(ApiEndpoints.coupleMessages);
```

### **3. 오류 처리**
```dart
try {
  final response = await ApiService.post(
    ApiEndpoints.coupleMessages,
    {'originalMessage': message},
  );
  
  final data = ApiService.parseResponse(response);
  // 성공 처리
  
} on UnauthorizedException {
  // 로그인 페이지로 이동
} on ApiException catch (e) {
  // 일반적인 API 오류 처리
  showError('오류: ${e.message}');
}
```

## 🔄 **마이그레이션 현황**

### **✅ 완료된 서비스**
- `ApiService`: 완전히 새 시스템으로 교체
- `CoupleMessageService`: ApiEndpoints 사용으로 변경
- `AuthService`: ApiEndpoints 사용으로 변경
- `LoginScreen`: ApiEndpoints 사용으로 변경
- `DiaryService`: 완전 마이그레이션 완료 (페이지네이션, 검색, 날짜 범위, 파일 업로드 포함)
- `TimeCapsuleService`: 완전 마이그레이션 완료 (고급 필터링 및 유틸리티 메서드 포함)
- `CoupleService`: 완전 마이그레이션 완료 (모든 커플 연결 로직)
- `NicknameService`: 완전 마이그레이션 완료 (닉네임 중복 확인 및 API 연동)
- `AnniversaryService`: 완전 마이그레이션 완료 (기념일 관리 및 마일스톤 계산)

## 🚀 **장점**

### **1. 중앙 집중식 관리**
- 모든 API 엔드포인트를 한 곳에서 관리
- URL 변경 시 한 파일만 수정하면 됨
- 타입 안전성 보장

### **2. 환경별 설정**
- 개발/스테이징/운영 환경 자동 전환
- 환경별 타임아웃, 로깅 설정 분리

### **3. 고급 기능**
- 자동 재시도 로직
- 구조화된 오류 처리
- 파일 업로드 지원
- 로깅 및 디버깅 도구

### **4. 개발 생산성**
- 코드 자동완성 지원
- 유틸리티 메서드로 반복 작업 최소화
- 일관된 API 호출 패턴

## 🎯 **다음 단계**

1. **API 버전 관리**: v1, v2 등 버전 지원
2. **캐싱 시스템**: 자주 사용되는 API 응답 캐싱
3. **오프라인 지원**: 네트워크 연결 없을 때 대체 동작
4. **성능 모니터링**: API 호출 통계 및 성능 추적
5. **실시간 통신**: WebSocket 지원 추가

---

🎉 **완벽한 중앙 집중식 API 관리 시스템 구축 완료!** 🎉

모든 서비스가 새로운 API 시스템으로 성공적으로 마이그레이션되었습니다. 이제 개발팀은 일관된 API 호출 패턴과 고급 기능들을 활용할 수 있습니다.