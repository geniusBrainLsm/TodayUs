package com.todayus.dto;

import com.todayus.entity.WeeklyFeedback;
import lombok.*;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.time.LocalDateTime;
import java.time.LocalDate;

public class WeeklyFeedbackDto {
    
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CreateRequest {
        
        @NotBlank(message = "서운했던 점을 입력해주세요")
        @Size(min = 10, max = 1000, message = "10자 이상 1000자 이하로 입력해주세요")
        private String message;
        
        public static WeeklyFeedback toEntity(CreateRequest request) {
            return WeeklyFeedback.builder()
                    .originalMessage(request.getMessage())
                    .build();
        }
    }
    
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Response {
        private Long id;
        private String senderName;
        private String senderNickname;
        private String receiverName;
        private String receiverNickname;
        private LocalDate weekOf;
        private String originalMessage;
        private String refinedMessage;
        private WeeklyFeedback.FeedbackStatus status;
        private Boolean isRead;
        private LocalDateTime createdAt;
        private LocalDateTime processedAt;
        private LocalDateTime deliveredAt;
        private LocalDateTime readAt;
        
        public static Response from(WeeklyFeedback feedback) {
            return Response.builder()
                    .id(feedback.getId())
                    .senderName(feedback.getSender().getName())
                    .senderNickname(feedback.getSender().getNickname())
                    .receiverName(feedback.getReceiver().getName())
                    .receiverNickname(feedback.getReceiver().getNickname())
                    .weekOf(feedback.getWeekOf())
                    .originalMessage(feedback.getOriginalMessage())
                    .refinedMessage(feedback.getRefinedMessage())
                    .status(feedback.getStatus())
                    .isRead(feedback.getIsRead())
                    .createdAt(feedback.getCreatedAt())
                    .processedAt(feedback.getProcessedAt())
                    .deliveredAt(feedback.getDeliveredAt())
                    .readAt(feedback.getReadAt())
                    .build();
        }
    }
    
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ListResponse {
        private Long id;
        private String partnerName;
        private String partnerNickname;
        private LocalDate weekOf;
        private String refinedMessage;
        private WeeklyFeedback.FeedbackStatus status;
        private Boolean isRead;
        private LocalDateTime createdAt;
        private String weekLabel; // "11월 2주차" 형태
        
        public static ListResponse from(WeeklyFeedback feedback, boolean isReceived) {
            // 받은 피드백인지 보낸 피드백인지에 따라 상대방 정보 결정
            String partnerName = isReceived ? feedback.getSender().getName() : feedback.getReceiver().getName();
            String partnerNickname = isReceived ? feedback.getSender().getNickname() : feedback.getReceiver().getNickname();
            
            return ListResponse.builder()
                    .id(feedback.getId())
                    .partnerName(partnerName)
                    .partnerNickname(partnerNickname)
                    .weekOf(feedback.getWeekOf())
                    .refinedMessage(feedback.getRefinedMessage())
                    .status(feedback.getStatus())
                    .isRead(feedback.getIsRead())
                    .createdAt(feedback.getCreatedAt())
                    .weekLabel(generateWeekLabel(feedback.getWeekOf()))
                    .build();
        }
        
        private static String generateWeekLabel(LocalDate weekOf) {
            int month = weekOf.getMonthValue();
            int dayOfMonth = weekOf.getDayOfMonth();
            int weekOfMonth = (dayOfMonth - 1) / 7 + 1;
            return month + "월 " + weekOfMonth + "주차";
        }
    }
    
    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class WeeklyAvailabilityResponse {
        private boolean canWrite;
        private String message;
        private LocalDate currentWeekOf;
        private boolean alreadyWritten;
        private LocalDateTime nextAvailableTime;
        
        public static WeeklyAvailabilityResponse available(LocalDate weekOf) {
            return WeeklyAvailabilityResponse.builder()
                    .canWrite(true)
                    .message("이번 주 서운했던 점을 작성할 수 있습니다.")
                    .currentWeekOf(weekOf)
                    .alreadyWritten(false)
                    .build();
        }
        
        public static WeeklyAvailabilityResponse alreadyWritten(LocalDate weekOf) {
            return WeeklyAvailabilityResponse.builder()
                    .canWrite(false)
                    .message("이번 주에 이미 피드백을 작성하셨습니다.")
                    .currentWeekOf(weekOf)
                    .alreadyWritten(true)
                    .build();
        }
        
        public static WeeklyAvailabilityResponse notAvailableTime(LocalDateTime nextAvailableTime) {
            return WeeklyAvailabilityResponse.builder()
                    .canWrite(false)
                    .message("피드백은 매주 토요일 오전 7시부터 오후 11시 59분까지만 작성 가능합니다.")
                    .nextAvailableTime(nextAvailableTime)
                    .build();
        }
    }
}