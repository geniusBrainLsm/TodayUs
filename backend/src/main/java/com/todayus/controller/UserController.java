package com.todayus.controller;

import com.todayus.dto.NicknameDto;
import com.todayus.dto.UserDto;
import com.todayus.security.JwtTokenProvider;
import com.todayus.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {
    
    private final UserService userService;
    private final JwtTokenProvider jwtTokenProvider;
    
    @PutMapping("/nickname")
    public ResponseEntity<?> updateNickname(@RequestHeader("Authorization") String authorization,
                                          @Valid @RequestBody NicknameDto nicknameDto) {
        try {
            String token = authorization.substring(7); // "Bearer " 제거
            
            if (!jwtTokenProvider.validateToken(token)) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(Map.of("error", "유효하지 않은 토큰입니다."));
            }
            
            Long userId = Long.valueOf(jwtTokenProvider.getUserId(token));
            UserDto updatedUser = userService.updateNickname(userId, nicknameDto.getNickname());
            
            Map<String, Object> response = new HashMap<>();
            response.put("message", "닉네임이 성공적으로 업데이트되었습니다.");
            response.put("user", updatedUser);
            
            return ResponseEntity.ok(response);
            
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            log.error("닉네임 업데이트 실패", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "닉네임 업데이트에 실패했습니다."));
        }
    }
    
    @GetMapping("/nickname/check")
    public ResponseEntity<?> checkNicknameAvailability(@RequestParam String nickname) {
        try {
            boolean available = userService.isNicknameAvailable(nickname);
            
            Map<String, Object> response = new HashMap<>();
            response.put("available", available);
            response.put("message", available ? "사용 가능한 닉네임입니다." : "이미 사용중인 닉네임입니다.");
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            log.error("닉네임 중복 검사 실패", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "닉네임 중복 검사에 실패했습니다."));
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
            
            Long userId = Long.valueOf(jwtTokenProvider.getUserId(token));
            return userService.findById(userId)
                    .map(user -> ResponseEntity.ok((Object) user))
                    .orElse(ResponseEntity.status(HttpStatus.NOT_FOUND)
                            .body(Map.of("error", "사용자를 찾을 수 없습니다.")));
            
        } catch (Exception e) {
            log.error("사용자 정보 조회 실패", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "사용자 정보 조회에 실패했습니다."));
        }
    }
}