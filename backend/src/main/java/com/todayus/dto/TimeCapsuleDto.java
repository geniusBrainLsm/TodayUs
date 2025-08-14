package com.todayus.dto;

import com.todayus.entity.TimeCapsule;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;
import java.time.LocalDateTime;

public class TimeCapsuleDto {
    
    @Getter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class CreateRequest {
        @NotBlank(message = "제목은 필수입니다.")
        @Size(max = 200, message = "제목은 200자를 초과할 수 없습니다.")
        private String title;
        
        @NotBlank(message = "내용은 필수입니다.")
        @Size(max = 5000, message = "내용은 5000자를 초과할 수 없습니다.")
        private String content;
        
        @NotNull(message = "오픈 날짜는 필수입니다.")
        private LocalDate openDate;
        
        @NotNull(message = "타임캡슐 타입은 필수입니다.")
        private TimeCapsule.TimeCapsuleType type;
    }
    
    @Getter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class Response {
        private Long id;
        private String title;
        private String content;
        private LocalDate openDate;
        private Boolean isOpened;
        private LocalDateTime openedAt;
        private LocalDateTime createdAt;
        private TimeCapsule.TimeCapsuleType type;
        private AuthorInfo author;
        
        @Getter
        @NoArgsConstructor
        @AllArgsConstructor
        @Builder
        public static class AuthorInfo {
            private Long id;
            private String nickname;
            private String email;
        }
        
        public static Response from(TimeCapsule timeCapsule) {
            return Response.builder()
                    .id(timeCapsule.getId())
                    .title(timeCapsule.getTitle())
                    .content(timeCapsule.getContent())
                    .openDate(timeCapsule.getOpenDate())
                    .isOpened(timeCapsule.getIsOpened())
                    .openedAt(timeCapsule.getOpenedAt())
                    .createdAt(timeCapsule.getCreatedAt())
                    .type(timeCapsule.getType())
                    .author(AuthorInfo.builder()
                            .id(timeCapsule.getAuthor().getId())
                            .nickname(timeCapsule.getAuthor().getNickname())
                            .email(timeCapsule.getAuthor().getEmail())
                            .build())
                    .build();
        }
    }
    
    @Getter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class ListResponse {
        private Long id;
        private String title;
        private LocalDate openDate;
        private Boolean isOpened;
        private LocalDateTime openedAt;
        private LocalDateTime createdAt;
        private TimeCapsule.TimeCapsuleType type;
        private AuthorInfo author;
        private boolean canOpen;
        
        @Getter
        @NoArgsConstructor
        @AllArgsConstructor
        @Builder
        public static class AuthorInfo {
            private Long id;
            private String nickname;
        }
        
        public static ListResponse from(TimeCapsule timeCapsule) {
            return ListResponse.builder()
                    .id(timeCapsule.getId())
                    .title(timeCapsule.getTitle())
                    .openDate(timeCapsule.getOpenDate())
                    .isOpened(timeCapsule.getIsOpened())
                    .openedAt(timeCapsule.getOpenedAt())
                    .createdAt(timeCapsule.getCreatedAt())
                    .type(timeCapsule.getType())
                    .author(AuthorInfo.builder()
                            .id(timeCapsule.getAuthor().getId())
                            .nickname(timeCapsule.getAuthor().getNickname())
                            .build())
                    .canOpen(timeCapsule.canOpen())
                    .build();
        }
    }
    
    @Getter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class Summary {
        private long totalCount;
        private long openedCount;
        private long unopenedCount;
        private long openableCount;
    }
}