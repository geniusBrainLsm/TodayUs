package com.todayus.dto;

import com.todayus.entity.CoupleMessage;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.time.LocalDateTime;

public class CoupleMessageDto {
    
    @Getter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class CreateRequest {
        @NotBlank(message = "전달할 메시지는 필수입니다.")
        @Size(max = 1000, message = "메시지는 1000자를 초과할 수 없습니다.")
        private String originalMessage;
    }
    
    @Getter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class Response {
        private Long id;
        private String originalMessage;
        private String aiProcessedMessage;
        private String status;
        private SenderInfo sender;
        private ReceiverInfo receiver;
        private LocalDateTime createdAt;
        private LocalDateTime deliveredAt;
        private LocalDateTime readAt;
        
        @Getter
        @NoArgsConstructor
        @AllArgsConstructor
        @Builder
        public static class SenderInfo {
            private Long id;
            private String nickname;
            private String email;
        }
        
        @Getter
        @NoArgsConstructor
        @AllArgsConstructor
        @Builder
        public static class ReceiverInfo {
            private Long id;
            private String nickname;
            private String email;
        }
        
        public static Response from(CoupleMessage message) {
            return Response.builder()
                    .id(message.getId())
                    .originalMessage(message.getOriginalMessage())
                    .aiProcessedMessage(message.getAiProcessedMessage())
                    .status(message.getStatus().name())
                    .sender(SenderInfo.builder()
                            .id(message.getSender().getId())
                            .nickname(message.getSender().getNickname())
                            .email(message.getSender().getEmail())
                            .build())
                    .receiver(ReceiverInfo.builder()
                            .id(message.getReceiver().getId())
                            .nickname(message.getReceiver().getNickname())
                            .email(message.getReceiver().getEmail())
                            .build())
                    .createdAt(message.getCreatedAt())
                    .deliveredAt(message.getDeliveredAt())
                    .readAt(message.getReadAt())
                    .build();
        }
    }
    
    @Getter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class PopupResponse {
        private Long id;
        private String aiProcessedMessage;
        private String senderNickname;
        private LocalDateTime createdAt;
        
        public static PopupResponse from(CoupleMessage message) {
            return PopupResponse.builder()
                    .id(message.getId())
                    .aiProcessedMessage(message.getAiProcessedMessage())
                    .senderNickname(message.getSender().getNickname())
                    .createdAt(message.getCreatedAt())
                    .build();
        }
    }
    
    @Getter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class WeeklyUsage {
        private long usedCount;
        private long maxCount;
        private boolean canSend;
        private LocalDateTime nextAvailableAt;
        
        public static WeeklyUsage of(long usedCount, long maxCount, boolean canSend, LocalDateTime nextAvailableAt) {
            return WeeklyUsage.builder()
                    .usedCount(usedCount)
                    .maxCount(maxCount)
                    .canSend(canSend)
                    .nextAvailableAt(nextAvailableAt)
                    .build();
        }
    }
}