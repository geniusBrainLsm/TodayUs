package com.todayus.controller;

import com.todayus.dto.NotificationDto;
import com.todayus.service.NotificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
@Slf4j
public class NotificationController {
    
    private final NotificationService notificationService;
    
    /**
     * FCM 토큰 등록/업데이트
     */
    @PostMapping("/register-token")
    public ResponseEntity<Map<String, String>> registerToken(
            @RequestBody NotificationDto.TokenUpdateRequest request,
            @RequestHeader("Authorization") String authHeader) {
        
        try {
            // TODO: JWT에서 사용자 ID 추출
            Long userId = extractUserIdFromToken(authHeader);
            
            notificationService.registerDevice(userId, request.getFcmToken(), request.getDeviceType());
            
            Map<String, String> response = new HashMap<>();
            response.put("message", "Token registered successfully");
            response.put("status", "success");
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            log.error("Error registering FCM token: {}", e.getMessage());
            Map<String, String> error = new HashMap<>();
            error.put("message", "Failed to register token");
            error.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }
    
    /**
     * 특정 사용자에게 알림 발송
     */
    @PostMapping("/send")
    public ResponseEntity<NotificationDto.SendResponse> sendNotification(
            @RequestBody NotificationDto.SendRequest request,
            @RequestHeader("Authorization") String authHeader) {
        
        try {
            // TODO: 관리자 권한 확인
            Long senderId = extractUserIdFromToken(authHeader);
            
            // TODO: recipientUserId를 request에서 받도록 수정
            Long recipientUserId = 1L; // 임시
            
            NotificationDto.SendResponse response = notificationService.sendNotificationToUser(
                recipientUserId,
                request.getTitle(),
                request.getBody(),
                request.getType(),
                request.getData()
            );
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            log.error("Error sending notification: {}", e.getMessage());
            NotificationDto.SendResponse error = NotificationDto.SendResponse.builder()
                .success(false)
                .message("Failed to send notification: " + e.getMessage())
                .build();
            return ResponseEntity.badRequest().body(error);
        }
    }
    
    /**
     * 커플 상대방에게 알림 발송
     */
    @PostMapping("/send-to-partner")
    public ResponseEntity<NotificationDto.SendResponse> sendToPartner(
            @RequestBody NotificationDto.SendRequest request,
            @RequestHeader("Authorization") String authHeader) {
        
        try {
            Long userId = extractUserIdFromToken(authHeader);
            
            NotificationDto.SendResponse response = notificationService.sendNotificationToPartner(
                userId,
                request.getTitle(),
                request.getBody(),
                request.getType(),
                request.getData()
            );
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            log.error("Error sending partner notification: {}", e.getMessage());
            NotificationDto.SendResponse error = NotificationDto.SendResponse.builder()
                .success(false)
                .message("Failed to send partner notification: " + e.getMessage())
                .build();
            return ResponseEntity.badRequest().body(error);
        }
    }
    
    /**
     * 일기 작성 리마인더 발송
     */
    @PostMapping("/diary-reminder")
    public ResponseEntity<Map<String, String>> sendDiaryReminder(
            @RequestHeader("Authorization") String authHeader) {
        
        try {
            Long userId = extractUserIdFromToken(authHeader);
            
            notificationService.sendDiaryReminderNotification(userId);
            
            Map<String, String> response = new HashMap<>();
            response.put("message", "Diary reminder sent successfully");
            response.put("status", "success");
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            log.error("Error sending diary reminder: {}", e.getMessage());
            Map<String, String> error = new HashMap<>();
            error.put("message", "Failed to send diary reminder");
            error.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }
    
    /**
     * 기념일 알림 발송
     */
    @PostMapping("/anniversary")
    public ResponseEntity<Map<String, String>> sendAnniversaryNotification(
            @RequestParam String anniversaryTitle,
            @RequestParam int daysCount,
            @RequestHeader("Authorization") String authHeader) {
        
        try {
            Long userId = extractUserIdFromToken(authHeader);
            
            notificationService.sendAnniversaryNotification(userId, anniversaryTitle, daysCount);
            
            Map<String, String> response = new HashMap<>();
            response.put("message", "Anniversary notification sent successfully");
            response.put("status", "success");
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            log.error("Error sending anniversary notification: {}", e.getMessage());
            Map<String, String> error = new HashMap<>();
            error.put("message", "Failed to send anniversary notification");
            error.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }
    
    /**
     * 테스트 알림 발송
     */
    @PostMapping("/test")
    public ResponseEntity<NotificationDto.SendResponse> sendTestNotification(
            @RequestHeader("Authorization") String authHeader) {
        
        try {
            Long userId = extractUserIdFromToken(authHeader);
            
            Map<String, String> data = new HashMap<>();
            data.put("type", "test");
            data.put("timestamp", String.valueOf(System.currentTimeMillis()));
            
            NotificationDto.SendResponse response = notificationService.sendNotificationToUser(
                userId,
                "🧪 테스트 알림",
                "알림이 정상적으로 작동합니다!",
                "test",
                data
            );
            
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            log.error("Error sending test notification: {}", e.getMessage());
            NotificationDto.SendResponse error = NotificationDto.SendResponse.builder()
                .success(false)
                .message("Failed to send test notification: " + e.getMessage())
                .build();
            return ResponseEntity.badRequest().body(error);
        }
    }
    
    /**
     * JWT 토큰에서 사용자 ID 추출 (임시 구현)
     */
    private Long extractUserIdFromToken(String authHeader) {
        // TODO: 실제 JWT 파싱 구현
        // 임시로 고정값 반환
        return 1L;
    }
}