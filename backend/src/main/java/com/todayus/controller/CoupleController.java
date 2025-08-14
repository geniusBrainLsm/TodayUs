package com.todayus.controller;

import com.todayus.dto.CoupleDto;
import com.todayus.dto.InviteCodeDto;
import com.todayus.security.JwtTokenProvider;
import com.todayus.service.CoupleService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@Slf4j
@RestController
@RequestMapping("/api/couples")
@RequiredArgsConstructor
public class CoupleController {
    
    private final CoupleService coupleService;
    private final JwtTokenProvider jwtTokenProvider;
    
    @PostMapping("/invite-code")
    public ResponseEntity<?> generateInviteCode(@RequestHeader("Authorization") String authorization) {
        try {
            Long userId = getUserIdFromToken(authorization);
            InviteCodeDto inviteCode = coupleService.generateInviteCode(userId);
            
            Map<String, Object> response = new HashMap<>();
            response.put("message", "초대 코드가 생성되었습니다.");
            response.put("inviteCode", inviteCode.getCode());
            response.put("inviteCodeData", inviteCode);
            
            return ResponseEntity.ok(response);
            
        } catch (IllegalStateException e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.CONFLICT).body(errorResponse);
        } catch (Exception e) {
            log.error("초대 코드 생성 실패", e);
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", "초대 코드 생성에 실패했습니다.");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }
    
    @PostMapping("/connect")
    public ResponseEntity<?> connectWithInviteCode(@RequestHeader("Authorization") String authorization,
                                                 @RequestBody InviteCodeDto.UseRequest request) {
        try {
            Long userId = getUserIdFromToken(authorization);
            CoupleDto couple = coupleService.connectWithInviteCode(userId, request.getCode());
            
            Map<String, Object> response = new HashMap<>();
            response.put("message", "커플 연결이 완료되었습니다.");
            response.put("couple", couple);
            
            return ResponseEntity.ok(response);
            
        } catch (IllegalArgumentException e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorResponse);
        } catch (IllegalStateException e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.CONFLICT).body(errorResponse);
        } catch (Exception e) {
            log.error("커플 연결 실패", e);
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", "커플 연결에 실패했습니다.");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }
    
    @GetMapping("/info")
    public ResponseEntity<?> getCoupleInfo(@RequestHeader("Authorization") String authorization) {
        try {
            Long userId = getUserIdFromToken(authorization);
            
            Optional<CoupleDto> coupleOpt = coupleService.getCoupleInfo(userId);
            
            Map<String, Object> response = new HashMap<>();
            response.put("couple", coupleOpt.orElse(null));
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            log.error("커플 정보 조회 실패", e);
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", "커플 정보 조회에 실패했습니다.");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(errorResponse);
        }
    }
    
    @GetMapping("/invite-code")
    public ResponseEntity<?> getActiveInviteCode(@RequestHeader("Authorization") String authorization) {
        try {
            Long userId = getUserIdFromToken(authorization);
            
            Optional<InviteCodeDto> inviteCodeOpt = coupleService.getActiveInviteCode(userId);
            
            Map<String, Object> response = new HashMap<>();
            response.put("inviteCode", inviteCodeOpt.orElse(null));
            
            return ResponseEntity.ok(response);
                    
        } catch (Exception e) {
            log.error("활성 초대 코드 조회 실패", e);
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", "초대 코드 조회에 실패했습니다.");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(errorResponse);
        }
    }
    
    @GetMapping("/invite-code/validate")
    public ResponseEntity<?> validateInviteCode(@RequestParam String code) {
        try {
            Map<String, Object> validationResult = coupleService.validateInviteCodeWithPartnerInfo(code);
            
            return ResponseEntity.ok(validationResult);
            
        } catch (Exception e) {
            log.error("초대 코드 검증 실패", e);
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", "초대 코드 검증에 실패했습니다.");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }
    
    @PostMapping("/invite-code/cancel")
    public ResponseEntity<?> cancelInviteCode(@RequestHeader("Authorization") String authorization) {
        try {
            Long userId = getUserIdFromToken(authorization);
            coupleService.cancelActiveInvites(userId);
            
            Map<String, Object> response = new HashMap<>();
            response.put("message", "초대 코드가 취소되었습니다.");
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            log.error("초대 코드 취소 실패", e);
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", "초대 코드 취소에 실패했습니다.");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }
    
    @DeleteMapping("/disconnect")
    public ResponseEntity<?> disconnectCouple(@RequestHeader("Authorization") String authorization) {
        try {
            Long userId = getUserIdFromToken(authorization);
            coupleService.disconnectCouple(userId);
            
            Map<String, Object> response = new HashMap<>();
            response.put("message", "커플 연결이 해제되었습니다.");
            return ResponseEntity.ok(response);
            
        } catch (IllegalArgumentException e) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorResponse);
        } catch (Exception e) {
            log.error("커플 연결 해제 실패", e);
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", "커플 연결 해제에 실패했습니다.");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }
    
    private Long getUserIdFromToken(String authorization) {
        if (authorization == null || authorization.length() < 8) {
            throw new IllegalArgumentException("Authorization 헤더가 올바르지 않습니다.");
        }
        
        String token = authorization.substring(7); // "Bearer " 제거
        
        if (token == null || token.trim().isEmpty()) {
            throw new IllegalArgumentException("토큰이 비어있습니다.");
        }
        
        if (!jwtTokenProvider.validateToken(token)) {
            throw new IllegalArgumentException("유효하지 않은 토큰입니다.");
        }
        
        String userIdString = jwtTokenProvider.getUserId(token);
        if (userIdString == null || userIdString.trim().isEmpty()) {
            throw new IllegalArgumentException("토큰에서 사용자 ID를 추출할 수 없습니다.");
        }
        
        try {
            return Long.valueOf(userIdString);
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("사용자 ID 형식이 올바르지 않습니다: " + userIdString);
        }
    }
}