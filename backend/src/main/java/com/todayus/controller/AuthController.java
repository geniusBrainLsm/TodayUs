package com.todayus.controller;

import com.todayus.dto.UserDto;
import com.todayus.entity.User;
import com.todayus.entity.Couple;
import com.todayus.repository.UserRepository;
import com.todayus.repository.CoupleRepository;
import com.todayus.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.reactive.function.client.WebClient;

import jakarta.servlet.http.HttpServletRequest;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@Slf4j
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {
    
    private final UserRepository userRepository;
    private final CoupleRepository coupleRepository;
    private final JwtTokenProvider jwtTokenProvider;
    private final WebClient.Builder webClientBuilder;
    
    @PostMapping("/kakao")
    public ResponseEntity<?> kakaoLogin(@RequestBody Map<String, String> request) {
        String accessToken = request.get("accessToken");
        
        try {
            // 카카오 API로 사용자 정보 가져오기
            Map<String, Object> kakaoUserInfo = getKakaoUserInfo(accessToken);
            
            String kakaoId = String.valueOf(kakaoUserInfo.get("id"));
            Map<String, Object> kakaoAccount = (Map<String, Object>) kakaoUserInfo.get("kakao_account");
            Map<String, Object> profile = (Map<String, Object>) kakaoAccount.get("profile");
            
            String email = (String) kakaoAccount.get("email");
            String name = (String) profile.get("nickname");
            String profileImageUrl = (String) profile.get("profile_image_url");
            
            // 사용자 저장 또는 업데이트
            User user = userRepository.findByProviderAndProviderId(User.Provider.KAKAO, kakaoId)
                    .map(existingUser -> existingUser.updateProfile(name, profileImageUrl))
                    .orElseGet(() -> userRepository.save(
                            User.builder()
                                    .email(email)
                                    .name(name)
                                    .profileImageUrl(profileImageUrl)
                                    .provider(User.Provider.KAKAO)
                                    .providerId(kakaoId)
                                    .role(User.Role.USER)
                                    .nicknameSet(false)
                                    .build()
                    ));
            
            // JWT 토큰 생성
            String token = jwtTokenProvider.createToken(user.getId().toString(), user.getEmail());
            
            // 사용자 온보딩 상태 확인
            Map<String, Object> onboardingStatus = getUserOnboardingStatus(user);
            
            Map<String, Object> response = new HashMap<>();
            response.put("token", token);
            response.put("user", UserDto.from(user));
            response.put("onboarding", onboardingStatus);
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            log.error("카카오 로그인 실패", e);
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "카카오 로그인에 실패했습니다."));
        }
    }
    
    @PostMapping("/google")
    public ResponseEntity<?> googleLogin(@RequestBody Map<String, String> request) {
        String accessToken = request.get("accessToken");
        String idToken = request.get("idToken");
        
        try {
            // accessToken 또는 idToken 중 하나는 있어야 함
            if (accessToken == null && idToken == null) {
                return ResponseEntity.badRequest()
                        .body(Map.of("error", "accessToken 또는 idToken이 필요합니다."));
            }
            
            final String googleId;
            final String email;
            final String name;
            final String profileImageUrl;
            
            if (accessToken != null) {
                // Access Token을 사용한 방식 (기존)
                Map<String, Object> googleUserInfo = getGoogleUserInfo(accessToken);
                googleId = (String) googleUserInfo.get("sub");
                email = (String) googleUserInfo.get("email");
                name = (String) googleUserInfo.get("name");
                profileImageUrl = (String) googleUserInfo.get("picture");
            } else {
                return ResponseEntity.badRequest()
                        .body(Map.of("error", "idToken 방식은 지원하지 않습니다. accessToken을 사용해주세요."));
            }
            
            // 사용자 저장 또는 업데이트
            User user = userRepository.findByProviderAndProviderId(User.Provider.GOOGLE, googleId)
                    .map(existingUser -> existingUser.updateProfile(name, profileImageUrl))
                    .orElseGet(() -> userRepository.save(
                            User.builder()
                                    .email(email)
                                    .name(name)
                                    .profileImageUrl(profileImageUrl)
                                    .provider(User.Provider.GOOGLE)
                                    .providerId(googleId)
                                    .role(User.Role.USER)
                                    .nicknameSet(false)
                                    .build()
                    ));
            
            // JWT 토큰 생성
            String token = jwtTokenProvider.createToken(user.getId().toString(), user.getEmail());
            
            // 사용자 온보딩 상태 확인
            Map<String, Object> onboardingStatus = getUserOnboardingStatus(user);
            
            Map<String, Object> response = new HashMap<>();
            response.put("token", token);
            response.put("user", UserDto.from(user));
            response.put("onboarding", onboardingStatus);
            
            log.info("Google login successful for user: {}", email);
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            log.error("구글 로그인 실패", e);
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "구글 로그인에 실패했습니다."));
        }
    }

    @GetMapping("/me")
    public ResponseEntity<?> getCurrentUser(@RequestHeader("Authorization") String authorization) {
        try {
            String token = authorization.substring(7); // "Bearer " 제거
            
            if (!jwtTokenProvider.validateToken(token)) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(Map.of("error", "유효하지 않은 토큰입니다."));
            }
            
            String userId = jwtTokenProvider.getUserId(token);
            Optional<User> user = userRepository.findById(Long.valueOf(userId));
            
            if (user.isPresent()) {
                return ResponseEntity.ok(UserDto.from(user.get()));
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(Map.of("error", "사용자를 찾을 수 없습니다."));
            }
            
        } catch (Exception e) {
            log.error("사용자 정보 조회 실패", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "사용자 정보 조회에 실패했습니다."));
        }
    }
    
    private Map<String, Object> getKakaoUserInfo(String accessToken) {
        return webClientBuilder.build()
                .get()
                .uri("https://kapi.kakao.com/v2/user/me")
                .header("Authorization", "Bearer " + accessToken)
                .retrieve()
                .bodyToMono(Map.class)
                .block();
    }
    
    @GetMapping("/kakao/test")
    public ResponseEntity<?> kakaoTest() {
        log.info("🟢 카카오 테스트 엔드포인트 호출됨");
        return ResponseEntity.ok(Map.of("message", "카카오 테스트 성공"));
    }
    
    @PostMapping("/reset-user-onboarding")
    public ResponseEntity<?> resetUserOnboarding(@RequestParam String email) {
        try {
            Optional<User> userOpt = userRepository.findByEmail(email);
            if (userOpt.isPresent()) {
                User user = userOpt.get();
                user.setNicknameSet(false);
                user.setNickname(null);
                userRepository.save(user);
                
                log.info("🟢 사용자 온보딩 초기화 완료: {}", email);
                return ResponseEntity.ok(Map.of("message", "사용자 온보딩 초기화 완료"));
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            log.error("🔴 사용자 온보딩 초기화 실패: {}", e.getMessage());
            return ResponseEntity.status(500).body(Map.of("error", e.getMessage()));
        }
    }
    
    @GetMapping("/debug-user")
    public ResponseEntity<?> debugUser(@RequestParam String email) {
        try {
            log.info("🟡 사용자 디버그 정보 조회: {}", email);
            
            Optional<User> userOpt = userRepository.findByEmail(email);
            if (userOpt.isPresent()) {
                User user = userOpt.get();
                
                Map<String, Object> debugInfo = new HashMap<>();
                debugInfo.put("id", user.getId());
                debugInfo.put("email", user.getEmail());
                debugInfo.put("name", user.getName());
                debugInfo.put("nickname", user.getNickname());
                debugInfo.put("nicknameSet", user.getNicknameSet());
                debugInfo.put("provider", user.getProvider().name());
                debugInfo.put("providerId", user.getProviderId());
                debugInfo.put("role", user.getRole().name());
                debugInfo.put("createdAt", user.getCreatedAt());
                debugInfo.put("updatedAt", user.getUpdatedAt());
                
                log.info("🟢 사용자 디버그 정보: {}", debugInfo);
                return ResponseEntity.ok(debugInfo);
            } else {
                log.warn("🟠 사용자 없음: {}", email);
                return ResponseEntity.status(404).body(Map.of("error", "사용자를 찾을 수 없습니다."));
            }
        } catch (Exception e) {
            log.error("🔴 사용자 디버그 정보 조회 실패: {}", e.getMessage(), e);
            return ResponseEntity.status(500).body(Map.of("error", e.getMessage()));
        }
    }
    
    @GetMapping("/onboarding-status")
    public ResponseEntity<?> getOnboardingStatus(@RequestParam String email) {
        try {
            log.info("🟡 온보딩 상태 조회 요청: {}", email);
            
            Optional<User> userOpt = userRepository.findByEmail(email);
            if (userOpt.isPresent()) {
                User user = userOpt.get();
                log.info("🟡 사용자 정보 - ID: {}, 이메일: {}, 닉네임: '{}', 닉네임설정됨: {}", 
                        user.getId(), user.getEmail(), user.getNickname(), user.getNicknameSet());
                
                Map<String, Object> onboardingStatus = getUserOnboardingStatus(user);
                
                Map<String, Object> response = new HashMap<>();
                response.put("user", UserDto.from(user));
                response.put("onboarding", onboardingStatus);
                
                log.info("🟢 온보딩 상태 조회 성공: {}", response);
                return ResponseEntity.ok(response);
            } else {
                log.warn("🟠 사용자 없음: {}", email);
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            log.error("🔴 온보딩 상태 조회 실패: {}", e.getMessage(), e);
            return ResponseEntity.status(500).body(Map.of("error", e.getMessage()));
        }
    }
    
    @PutMapping("/nickname")
    public ResponseEntity<?> updateNickname(@RequestHeader("Authorization") String authorization,
                                           @RequestBody Map<String, String> request) {
        try {
            String token = authorization.substring(7); // "Bearer " 제거
            
            if (!jwtTokenProvider.validateToken(token)) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(Map.of("error", "유효하지 않은 토큰입니다."));
            }
            
            String userId = jwtTokenProvider.getUserId(token);
            String nickname = request.get("nickname");
            
            if (nickname == null || nickname.trim().isEmpty()) {
                return ResponseEntity.badRequest()
                        .body(Map.of("error", "닉네임을 입력해주세요."));
            }
            
            // 닉네임 길이 검사 (문자 단위로 체크, 이모지 등 멀티바이트 문자 고려)
            String trimmedNickname = nickname.trim();
            int characterCount = trimmedNickname.codePointCount(0, trimmedNickname.length());
            
            if (characterCount < 2) {
                return ResponseEntity.badRequest()
                        .body(Map.of("error", "닉네임은 2글자 이상이어야 합니다."));
            }
            
            if (characterCount > 10) {
                return ResponseEntity.badRequest()
                        .body(Map.of("error", "닉네임은 10글자 이하여야 합니다."));
            }
            
            // 연속된 공백 체크
            if (trimmedNickname.matches(".*\\s{2,}.*")) {
                return ResponseEntity.badRequest()
                        .body(Map.of("error", "연속된 공백은 사용할 수 없습니다."));
            }
            
            // 닉네임 중복 체크
            if (userRepository.existsByNickname(trimmedNickname)) {
                return ResponseEntity.badRequest()
                        .body(Map.of("error", "이미 사용 중인 닉네임입니다."));
            }
            
            Optional<User> userOpt = userRepository.findById(Long.valueOf(userId));
            if (userOpt.isPresent()) {
                User user = userOpt.get();
                user.updateNickname(trimmedNickname);
                userRepository.save(user);
                
                log.info("🟢 닉네임 설정 완료: {} -> {}", user.getEmail(), trimmedNickname);
                
                // 업데이트된 온보딩 상태 반환
                Map<String, Object> onboardingStatus = getUserOnboardingStatus(user);
                
                Map<String, Object> response = new HashMap<>();
                response.put("user", UserDto.from(user));
                response.put("onboarding", onboardingStatus);
                response.put("message", "닉네임이 설정되었습니다.");
                
                return ResponseEntity.ok(response);
            } else {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(Map.of("error", "사용자를 찾을 수 없습니다."));
            }
            
        } catch (Exception e) {
            log.error("🔴 닉네임 설정 실패: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "닉네임 설정에 실패했습니다."));
        }
    }
    
    @GetMapping("/kakao/callback")
    public ResponseEntity<?> kakaoCallback(@RequestParam("code") String code, 
                                         @RequestParam(value = "state", required = false) String state,
                                         HttpServletRequest request) {
        try {
            log.info("🟡 카카오 OAuth2 콜백 수신 - URI: {}, code={}, state={}", 
                    request.getRequestURI(), code, state);
            
            // 카카오로부터 액세스 토큰 획득
            log.info("🟡 카카오 액세스 토큰 요청 시작");
            String accessToken = getKakaoAccessToken(code);
            log.info("🟢 카카오 액세스 토큰 획득 성공: {}...", accessToken.substring(0, Math.min(20, accessToken.length())));
            
            // 카카오 사용자 정보 획득
            log.info("🟡 카카오 사용자 정보 요청 시작");
            Map<String, Object> kakaoUserInfo = getKakaoUserInfo(accessToken);
            log.info("🟢 카카오 사용자 정보 획득 성공: {}", kakaoUserInfo);
            
            String kakaoId = String.valueOf(kakaoUserInfo.get("id"));
            Map<String, Object> kakaoAccount = (Map<String, Object>) kakaoUserInfo.get("kakao_account");
            Map<String, Object> profile = (Map<String, Object>) kakaoAccount.get("profile");
            
            String email = (String) kakaoAccount.get("email");
            String name = (String) profile.get("nickname");
            String profileImageUrl = (String) profile.get("profile_image_url");
            
            // 사용자 저장 또는 업데이트
            User user = userRepository.findByProviderAndProviderId(User.Provider.KAKAO, kakaoId)
                    .map(existingUser -> existingUser.updateProfile(name, profileImageUrl))
                    .orElseGet(() -> userRepository.save(
                            User.builder()
                                    .email(email)
                                    .name(name)
                                    .profileImageUrl(profileImageUrl)
                                    .provider(User.Provider.KAKAO)
                                    .providerId(kakaoId)
                                    .role(User.Role.USER)
                                    .nicknameSet(false)
                                    .build()
                    ));
            
            // JWT 토큰 생성
            String token = jwtTokenProvider.createToken(user.getId().toString(), user.getEmail());
            
            // 사용자 온보딩 상태 확인
            Map<String, Object> onboardingStatus = getUserOnboardingStatus(user);
            String nextStep = (String) onboardingStatus.get("nextStep");
            
            // Flutter 앱으로 리다이렉트 (토큰과 온보딩 정보 함께)
            String redirectUrl = String.format("todayus://login?token=%s&user_id=%d&next_step=%s", 
                    token, user.getId(), nextStep);
            return ResponseEntity.status(302)
                    .header("Location", redirectUrl)
                    .build();
                    
        } catch (Exception e) {
            log.error("🔴 카카오 콜백 처리 실패: {}", e.getMessage(), e);
            return ResponseEntity.status(500)
                    .body(Map.of("error", "카카오 로그인에 실패했습니다: " + e.getMessage()));
        }
    }
    
    private String getKakaoAccessToken(String code) {
        String tokenUrl = "https://kauth.kakao.com/oauth/token";
        
        // 환경변수가 제대로 로드되지 않으므로 직접 값 사용
        String kakaoClientId = "e74f4850d8af7e2b2aec20f4faa636b3";
        String kakaoClientSecret = "IOSjbcQZbcrB1NptoM85i9mHf1fRM5al";
        
        log.info("🟡 카카오 클라이언트 정보 - ID: {}, SECRET 존재여부: YES", kakaoClientId);
        
        // Form data 문자열 직접 구성
        String formData = String.format(
            "grant_type=authorization_code&client_id=%s&client_secret=%s&redirect_uri=%s&code=%s",
            kakaoClientId,
            kakaoClientSecret,
            "http://10.0.2.2:8080/api/auth/kakao/callback",
            code
        );
        
        log.info("🟡 카카오 토큰 요청 데이터: {}", formData);
        
        try {
            Map<String, Object> response = webClientBuilder.build()
                    .post()
                    .uri(tokenUrl)
                    .header("Content-Type", "application/x-www-form-urlencoded")
                    .bodyValue(formData)
                    .retrieve()
                    .bodyToMono(Map.class)
                    .block();
            
            log.info("🟢 카카오 토큰 응답: {}", response);
            return (String) response.get("access_token");
            
        } catch (Exception e) {
            log.error("🔴 카카오 토큰 요청 실패: {}", e.getMessage(), e);
            throw new RuntimeException("카카오 액세스 토큰 획득 실패: " + e.getMessage());
        }
    }
    
    private Map<String, Object> getGoogleUserInfo(String accessToken) {
        return webClientBuilder.build()
                .get()
                .uri("https://www.googleapis.com/oauth2/v3/userinfo")
                .header("Authorization", "Bearer " + accessToken)
                .retrieve()
                .bodyToMono(Map.class)
                .block();
    }
    
    private Map<String, Object> getUserOnboardingStatus(User user) {
        Map<String, Object> status = new HashMap<>();
        
        // 1. 닉네임 설정 여부
        boolean hasNickname = Boolean.TRUE.equals(user.getNicknameSet()) && 
                               user.getNickname() != null && !user.getNickname().trim().isEmpty();
        status.put("hasNickname", hasNickname);
        
        log.info("🟡 닉네임 체크 - nicknameSet: {}, nickname: '{}', hasNickname: {}", 
                user.getNicknameSet(), user.getNickname(), hasNickname);
        
        // 2. 커플 연결 여부
        Optional<Couple> couple = coupleRepository.findByUser1OrUser2(user);
        boolean hasCoupleConnection = couple.isPresent() && couple.get().getStatus() == Couple.CoupleStatus.CONNECTED;
        status.put("hasCoupleConnection", hasCoupleConnection);
        
        log.info("🟡 커플 체크 - userId: {}, couplePresent: {}, coupleStatus: {}, hasCoupleConnection: {}", 
                user.getId(), couple.isPresent(), 
                couple.isPresent() ? couple.get().getStatus() : "N/A", hasCoupleConnection);
        
        // 3. 기념일 설정 여부 (커플이 있는 경우만)
        boolean hasAnniversary = false;
        if (hasCoupleConnection) {
            Couple coupleEntity = couple.get();
            hasAnniversary = coupleEntity.hasAnniversaryDate();
            log.info("🟡 기념일 체크 - coupleId: {}, anniversaryDate: {}, hasAnniversary: {}", 
                    coupleEntity.getId(), coupleEntity.getAnniversaryDate(), hasAnniversary);
        } else {
            log.info("🟡 기념일 체크 - 커플 연결 없음");
        }
        status.put("hasAnniversary", hasAnniversary);
        
        // 4. 다음 단계 결정
        String nextStep;
        if (!hasNickname) {
            nextStep = "nickname";
        } else if (!hasCoupleConnection) {
            nextStep = "couple_connection";
        } else if (!hasAnniversary) {
            nextStep = "anniversary_setup";
        } else {
            nextStep = "home";
        }
        status.put("nextStep", nextStep);
        
        log.info("🟡 사용자 온보딩 상태 - 닉네임: {}, 커플연결: {}, 기념일: {}, 다음단계: {}", 
                hasNickname, hasCoupleConnection, hasAnniversary, nextStep);
        
        return status;
    }
}