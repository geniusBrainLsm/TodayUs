package com.todayus.service;

import com.todayus.dto.NotificationDto;
import com.todayus.entity.UserDevice;
import com.todayus.repository.UserDeviceRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
public class NotificationService {
    
    private final UserDeviceRepository userDeviceRepository;
    private final FCMService fcmService;
    
    /**
     * FCM 토큰 등록/업데이트
     */
    @Transactional
    public void registerDevice(Long userId, String fcmToken, String deviceType) {
        try {
            // 기존 토큰 확인
            Optional<UserDevice> existingDevice = userDeviceRepository.findByFcmToken(fcmToken);
            
            if (existingDevice.isPresent()) {
                // 기존 기기 정보 업데이트
                UserDevice device = existingDevice.get();
                device.setUserId(userId);
                device.setDeviceType(deviceType);
                device.setLastUsedAt(LocalDateTime.now());
                device.setIsActive(true);
                userDeviceRepository.save(device);
                log.info("Updated existing device for user {}: {}", userId, fcmToken.substring(0, 20));
            } else {
                // 새 기기 등록
                UserDevice newDevice = UserDevice.builder()
                    .userId(userId)
                    .fcmToken(fcmToken)
                    .deviceType(deviceType)
                    .isActive(true)
                    .build();
                userDeviceRepository.save(newDevice);
                log.info("Registered new device for user {}: {}", userId, fcmToken.substring(0, 20));
            }
        } catch (Exception e) {
            log.error("Error registering device for user {}: {}", userId, e.getMessage());
            throw new RuntimeException("Failed to register device", e);
        }
    }
    
    /**
     * 사용자에게 알림 발송
     */
    public NotificationDto.SendResponse sendNotificationToUser(Long userId, String title, String body, String type, Map<String, String> data) {
        try {
            List<UserDevice> devices = userDeviceRepository.findByUserIdAndIsActiveTrue(userId);
            
            if (devices.isEmpty()) {
                log.warn("No active devices found for user {}", userId);
                return NotificationDto.SendResponse.builder()
                    .success(false)
                    .message("No active devices found")
                    .build();
            }
            
            boolean anySuccess = false;
            String lastMessageId = null;
            
            for (UserDevice device : devices) {
                try {
                    String messageId = fcmService.sendNotification(device.getFcmToken(), title, body, data);
                    if (messageId != null) {
                        anySuccess = true;
                        lastMessageId = messageId;
                        log.info("Notification sent to device {}: {}", device.getFcmToken().substring(0, 20), messageId);
                    }
                } catch (Exception e) {
                    log.error("Failed to send notification to device {}: {}", device.getFcmToken().substring(0, 20), e.getMessage());
                    // 토큰이 유효하지 않은 경우 비활성화
                    if (e.getMessage().contains("Requested entity was not found")) {
                        device.setIsActive(false);
                        userDeviceRepository.save(device);
                    }
                }
            }
            
            return NotificationDto.SendResponse.builder()
                .success(anySuccess)
                .message(anySuccess ? "Notification sent successfully" : "Failed to send to any device")
                .messageId(lastMessageId)
                .build();
                
        } catch (Exception e) {
            log.error("Error sending notification to user {}: {}", userId, e.getMessage());
            return NotificationDto.SendResponse.builder()
                .success(false)
                .message("Internal error: " + e.getMessage())
                .build();
        }
    }
    
    /**
     * 커플 상대방에게 알림 발송
     */
    public NotificationDto.SendResponse sendNotificationToPartner(Long userId, String title, String body, String type, Map<String, String> data) {
        try {
            List<UserDevice> partnerDevices = userDeviceRepository.findPartnerDevices(userId);
            
            if (partnerDevices.isEmpty()) {
                log.warn("No partner devices found for user {}", userId);
                return NotificationDto.SendResponse.builder()
                    .success(false)
                    .message("No partner devices found")
                    .build();
            }
            
            boolean anySuccess = false;
            String lastMessageId = null;
            
            for (UserDevice device : partnerDevices) {
                try {
                    String messageId = fcmService.sendNotification(device.getFcmToken(), title, body, data);
                    if (messageId != null) {
                        anySuccess = true;
                        lastMessageId = messageId;
                        log.info("Partner notification sent to device {}: {}", device.getFcmToken().substring(0, 20), messageId);
                    }
                } catch (Exception e) {
                    log.error("Failed to send partner notification to device {}: {}", device.getFcmToken().substring(0, 20), e.getMessage());
                }
            }
            
            return NotificationDto.SendResponse.builder()
                .success(anySuccess)
                .message(anySuccess ? "Partner notification sent successfully" : "Failed to send to any partner device")
                .messageId(lastMessageId)
                .build();
                
        } catch (Exception e) {
            log.error("Error sending partner notification for user {}: {}", userId, e.getMessage());
            return NotificationDto.SendResponse.builder()
                .success(false)
                .message("Internal error: " + e.getMessage())
                .build();
        }
    }
    
    /**
     * 일기 댓글 알림 발송
     */
    public void sendDiaryCommentNotification(
            Long commenterUserId,
            String commenterNickname,
            Long diaryId,
            String diaryTitle,
            Long commentId,
            String commentContent
    ) {
        try {
            String safeNickname = (commenterNickname != null && !commenterNickname.isBlank())
                    ? commenterNickname
                    : "파트너";

            Map<String, String> data = new HashMap<>();
            data.put("type", "diary_comment");
            data.put("action", "navigate_to_diary_comment");
            data.put("diary_id", diaryId.toString());
            data.put("author_name", safeNickname);
            if (diaryTitle != null && !diaryTitle.isBlank()) {
                data.put("diary_title", diaryTitle);
            }
            if (commentId != null) {
                data.put("comment_id", commentId.toString());
            }

            String preview = commentContent != null ? commentContent.trim() : "";
            if (preview.length() > 50) {
                preview = preview.substring(0, 50) + "...";
            }
            if (preview.isEmpty()) {
                preview = "새로운 댓글을 확인해보세요!";
            }

            sendNotificationToPartner(
                commenterUserId,
                String.format("\uD83D\uDCAC %s님이 댓글을 남겼어요", safeNickname),
                preview,
                "diary_comment",
                data
            );

            log.info("Diary comment notification sent request for diary {} by user {}", diaryId, commenterUserId);
        } catch (Exception e) {
            log.error("Error sending diary comment notification for diary {} by user {}: {}", diaryId, commenterUserId, e.getMessage());
        }
    }

    /**
     * 일기 작성 알림 발송
     */
    public void sendDiaryReminderNotification(Long userId) {
        Map<String, String> data = new HashMap<>();
        data.put("type", "diary_reminder");
        data.put("action", "navigate_to_diary_write");
        
        sendNotificationToUser(
            userId,
            "오늘 일기 작성하셨나요? ✍️",
            "하루를 마무리하며 소중한 순간들을 기록해보세요",
            "diary_reminder",
            data
        );
    }
    
    /**
     * 기념일 알림 발송
     */
    public void sendAnniversaryNotification(Long userId, String anniversaryTitle, int daysCount) {
        Map<String, String> data = new HashMap<>();
        data.put("type", "anniversary");
        data.put("action", "navigate_to_anniversary");
        data.put("anniversary_title", anniversaryTitle);
        data.put("days_count", String.valueOf(daysCount));
        
        sendNotificationToUser(
            userId,
            String.format("🎉 %s", anniversaryTitle),
            String.format("오늘은 특별한 날이에요! D+%d 축하합니다 💕", daysCount),
            "anniversary",
            data
        );
    }
    
    /**
     * 커플 메시지 알림 발송
     */
    public void sendCoupleMessageNotification(Long senderUserId, String senderName, String messagePreview) {
        Map<String, String> data = new HashMap<>();
        data.put("type", "couple_message");
        data.put("action", "navigate_to_couple_message");
        data.put("sender_name", senderName);
        
        sendNotificationToPartner(
            senderUserId,
            String.format("💌 %s님의 메시지", senderName),
            messagePreview.length() > 50 ? messagePreview.substring(0, 50) + "..." : messagePreview,
            "couple_message",
            data
        );
    }
    
    /**
     * 주간 피드백 알림 발송
     */
    public void sendWeeklyFeedbackNotification(Long userId, String partnerName) {
        Map<String, String> data = new HashMap<>();
        data.put("type", "weekly_feedback");
        data.put("action", "navigate_to_weekly_feedback");
        
        sendNotificationToUser(
            userId,
            "📊 주간 감정 분석 완료",
            String.format("%s님과의 이번 주 감정 분석 결과가 나왔어요", partnerName),
            "weekly_feedback",
            data
        );
    }
    
    /**
     * 전체 사용자에게 공지 발송
     */
    public void sendBroadcastNotification(String title, String body, Map<String, String> data) {
        try {
            List<UserDevice> allDevices = userDeviceRepository.findAllActiveDevices();
            log.info("Sending broadcast notification to {} devices", allDevices.size());
            
            for (UserDevice device : allDevices) {
                try {
                    fcmService.sendNotification(device.getFcmToken(), title, body, data);
                    Thread.sleep(100); // Rate limiting
                } catch (Exception e) {
                    log.error("Failed to send broadcast to device {}: {}", device.getFcmToken().substring(0, 20), e.getMessage());
                }
            }
        } catch (Exception e) {
            log.error("Error sending broadcast notification: {}", e.getMessage());
        }
    }
    
    /**
     * 비활성 기기 정리
     */
    @Transactional
    public void cleanupInactiveDevices() {
        try {
            LocalDateTime cutoffDate = LocalDateTime.now().minusDays(30);
            List<UserDevice> inactiveDevices = userDeviceRepository.findInactiveDevices(cutoffDate);
            
            for (UserDevice device : inactiveDevices) {
                device.setIsActive(false);
            }
            
            userDeviceRepository.saveAll(inactiveDevices);
            log.info("Deactivated {} inactive devices", inactiveDevices.size());
        } catch (Exception e) {
            log.error("Error cleaning up inactive devices: {}", e.getMessage());
        }
    }
}