package com.todayus.controller;

import com.todayus.dto.UserDto;
import com.todayus.entity.User;
import com.todayus.repository.UserRepository;
import com.todayus.security.JwtTokenProvider;
import com.todayus.service.RobotStoreService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminAuthController {

    private static final String ADMIN_USERNAME = "lsm";
    private static final String ADMIN_PASSWORD = "erdwvudr2qvud1!!";
    private static final String ADMIN_EMAIL = "geniusbrainlsm@gmail.com";

    private final UserRepository userRepository;
    private final JwtTokenProvider jwtTokenProvider;
    private final RobotStoreService robotStoreService;

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody Map<String, String> payload) {
        String username = payload.getOrDefault("username", "").trim();
        String password = payload.getOrDefault("password", "").trim();

        if (!ADMIN_USERNAME.equals(username) || !ADMIN_PASSWORD.equals(password)) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "잘못된 관리자 자격 증명입니다."));
        }

        User adminUser = userRepository.findByEmail(ADMIN_EMAIL)
                .orElseGet(() -> userRepository.save(
                        User.builder()
                                .email(ADMIN_EMAIL)
                                .name("관리자")
                                .provider(User.Provider.GOOGLE)
                                .providerId("admin")
                                .role(User.Role.ADMIN)
                                .nickname("관리자")
                                .nicknameSet(true)
                                .build()
                ));

        robotStoreService.ensureActiveRobot(adminUser);

        String token = jwtTokenProvider.createToken(adminUser.getId().toString(), adminUser.getEmail());

        return ResponseEntity.ok(Map.of(
                "token", token,
                "user", UserDto.from(adminUser)
        ));
    }
}
