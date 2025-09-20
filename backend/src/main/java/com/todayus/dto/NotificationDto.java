package com.todayus.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.Map;

public class NotificationDto {
    
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SendRequest {
        private String recipientToken;
        private String title;
        private String body;
        private Map<String, String> data;
        private String type; // diary_reminder, diary_created, diary_comment, couple_message
    }
    
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SendResponse {
        private boolean success;
        private String message;
        private String messageId;
    }
    
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class TokenUpdateRequest {
        private String fcmToken;
        private String deviceType; // android, ios, web
    }
    
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ScheduleRequest {
        private String title;
        private String body;
        private String type;
        private String scheduledTime; // ISO 8601 format
        private Map<String, String> data;
    }
    
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class BulkSendRequest {
        private String title;
        private String body;
        private String type;
        private Map<String, String> data;
        // 모든 활성 사용자에게 발송
    }
}