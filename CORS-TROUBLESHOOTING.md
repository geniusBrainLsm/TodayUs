# CORS 문제 해결 가이드

## 🎯 CORS란?
Cross-Origin Resource Sharing (CORS)는 웹 브라우저에서 다른 도메인의 리소스에 접근할 때의 보안 정책입니다.

## 🔧 설정된 CORS 정책

### 백엔드 (Spring Boot)
현재 설정된 허용 도메인:
- `http://localhost:*` - 로컬 개발
- `http://127.0.0.1:*` - 로컬 개발
- `http://10.0.2.2:*` - Android 에뮬레이터
- `http://192.168.*.*:*` - 로컬 네트워크 (실제 디바이스)
- `https://*.railway.app` - Railway 배포
- `https://todayus.com`, `https://*.todayus.com` - 프로덕션 도메인

허용 메서드: GET, POST, PUT, DELETE, OPTIONS, PATCH
허용 헤더: Authorization, Content-Type, Accept, Origin 등

### AWS S3
업로드된 이미지 접근을 위한 CORS 설정:
- 모든 도메인에서 GET, PUT, POST, DELETE 허용
- 헤더: 모든 헤더 허용

## 🚨 일반적인 CORS 오류

### 1. "Access to fetch at ... from origin ... has been blocked by CORS policy"
**원인**: 요청하는 도메인이 허용 목록에 없음
**해결방법**:
1. 백엔드 SecurityConfig.java 확인
2. 허용 도메인 목록에 추가
3. 서버 재시작

### 2. "Response to preflight request doesn't pass access control check"
**원인**: OPTIONS 요청 처리 실패
**해결방법**:
1. CorsTestController의 OPTIONS 엔드포인트 확인
2. 브라우저 개발자 도구에서 OPTIONS 요청 상태 확인

### 3. Mobile 앱에서 CORS 오류
**원인**: Flutter HTTP 클라이언트는 일반적으로 CORS 제한이 없지만, WebView 사용 시 발생
**해결방법**:
1. 네이티브 HTTP 클라이언트 사용 확인
2. WebView 사용 시 CORS 헤더 추가

## 🔍 디버깅 방법

### 1. Flutter 앱에서 CORS 테스트
```dart
// 앱에서 설정 > 개발자 도구 > 환경 설정 > CORS 테스트 실행
```

### 2. 브라우저 개발자 도구 확인
1. F12로 개발자 도구 열기
2. Network 탭에서 요청 확인
3. OPTIONS 요청과 실제 요청 모두 확인
4. Response Headers에서 Access-Control-* 헤더 확인

### 3. 명령줄 테스트
```bash
# 간단한 GET 요청
curl -H "Origin: http://localhost:3000" \
     -v \
     https://todayus-backend-production.up.railway.app/api/cors-test/simple

# Preflight 요청 시뮬레이션
curl -H "Origin: http://localhost:3000" \
     -H "Access-Control-Request-Method: POST" \
     -H "Access-Control-Request-Headers: Content-Type" \
     -X OPTIONS \
     -v \
     https://todayus-backend-production.up.railway.app/api/cors-test/preflight
```

### 4. 로그 확인
백엔드 로그에서 다음 메시지 확인:
```
CORS GET 테스트 요청 받음
CORS POST 테스트 요청 받음: {test=preflight, timestamp=...}
OPTIONS 요청 처리됨
```

## 🛠️ 환경별 해결 방법

### 개발 환경 (로컬)
1. **에뮬레이터**: `http://10.0.2.2:8080` 사용
2. **실제 디바이스**: PC IP 주소로 `environment.dart` 수정
3. **웹**: `http://localhost:8080` 사용

### 스테이징/프로덕션 환경
1. Railway URL 사용: `https://todayus-backend-production.up.railway.app`
2. 도메인 허용 목록에 프론트엔드 도메인 추가
3. HTTPS 사용 강제

## 📋 체크리스트

### 배포 전 확인
- [ ] SecurityConfig.java에 모든 필요한 도메인 추가
- [ ] CorsTestController 엔드포인트 동작 확인
- [ ] 로컬에서 모든 CORS 테스트 통과

### 배포 후 확인
- [ ] Railway 환경 변수 설정 완료
- [ ] CORS 테스트 엔드포인트 접근 가능
- [ ] Flutter 앱에서 CORS 테스트 통과
- [ ] 실제 API 호출 성공

### S3 이미지 업로드 확인
- [ ] S3 버킷 CORS 정책 설정
- [ ] 업로드된 이미지 웹에서 접근 가능
- [ ] 앱에서 이미지 표시 정상

## 🚀 추가 최적화

### 프로덕션 보안 강화
```java
// SecurityConfig.java 수정 - 구체적인 도메인만 허용
configuration.setAllowedOriginPatterns(Arrays.asList(
    "https://todayus.com",
    "https://app.todayus.com",
    "https://admin.todayus.com"
));
```

### 캐시 최적화
```java
configuration.setMaxAge(86400L); // 24시간 캐시
```

### 에러 로깅 강화
```java
@Bean
public CorsFilter corsFilter() {
    return new CorsFilter(corsConfigurationSource()) {
        @Override
        protected void doFilterInternal(HttpServletRequest request, 
                                      HttpServletResponse response, 
                                      FilterChain filterChain) throws ServletException, IOException {
            log.info("CORS 요청: Origin={}, Method={}, URI={}", 
                    request.getHeader("Origin"), 
                    request.getMethod(), 
                    request.getRequestURI());
            super.doFilterInternal(request, response, filterChain);
        }
    };
}
```

## ❗ 주의사항

1. **와일드카드 사용 금지**: 프로덕션에서는 `*` 대신 구체적인 도메인 사용
2. **Credentials와 와일드카드**: `allowCredentials(true)`일 때는 와일드카드 사용 불가
3. **모바일 앱**: 네이티브 HTTP 클라이언트는 CORS 제한 없음
4. **개발 vs 프로덕션**: 개발 환경에서는 느슨하게, 프로덕션에서는 엄격하게