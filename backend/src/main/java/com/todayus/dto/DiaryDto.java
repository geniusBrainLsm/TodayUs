package com.todayus.dto;

import com.todayus.entity.Diary;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

public class DiaryDto {
    
    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class CreateRequest {
        @NotBlank(message = "제목은 필수입니다.")
        private String title;
        
        @NotBlank(message = "내용은 필수입니다.")
        private String content;
        
        @NotNull(message = "일기 날짜는 필수입니다.")
        private LocalDate diaryDate;
        
        private String moodEmoji;
        
        private String imageUrl;
    }
    
    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class UpdateRequest {
        @NotBlank(message = "제목은 필수입니다.")
        private String title;
        
        @NotBlank(message = "내용은 필수입니다.")
        private String content;
        
        private String moodEmoji;
        
        private String imageUrl;
    }
    
    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class Response {
        private Long id;
        private String title;
        private String content;
        private LocalDate diaryDate;
        private String moodEmoji;
        private String imageUrl;
        private String aiEmotion;
        private String aiComment;
        private boolean aiProcessed;
        private String status;
        private UserInfo author;
        private LocalDateTime createdAt;
        private LocalDateTime updatedAt;
        private List<CommentResponse> comments;
        private long commentCount;
        
        public static Response from(Diary diary) {
            // Note: This method is deprecated, use from(Diary, User) instead
            throw new UnsupportedOperationException("Use from(Diary, User) method instead");
        }
        
        public static Response from(Diary diary, com.todayus.entity.User author) {
            return Response.builder()
                    .id(diary.getId())
                    .title(diary.getTitle())
                    .content(diary.getContent())
                    .diaryDate(diary.getDiaryDate())
                    .moodEmoji(diary.getMoodEmoji())
                    .imageUrl(diary.getImageUrl())
                    .aiEmotion(diary.getAiEmotion())
                    .aiComment(diary.getAiComment())
                    .aiProcessed(diary.getAiProcessed())
                    .status(diary.getStatus().name())
                    .author(UserInfo.from(author))
                    .createdAt(diary.getCreatedAt())
                    .updatedAt(diary.getUpdatedAt())
                    .build();
        }
        
        public static Response fromWithComments(Diary diary, com.todayus.entity.User author, List<CommentResponse> comments) {
            Response response = from(diary, author);
            response.setComments(comments);
            response.setCommentCount(comments.size());
            return response;
        }
    }
    
    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class ListResponse {
        private Long id;
        private String title;
        private LocalDate diaryDate;
        private String moodEmoji;
        private String imageUrl;
        private String aiEmotion;
        private boolean aiProcessed;
        private UserInfo author;
        private LocalDateTime createdAt;
        private long commentCount;
        
        public static ListResponse from(Diary diary, long commentCount) {
            // Note: This method is deprecated, use from(Diary, User, long) instead
            throw new UnsupportedOperationException("Use from(Diary, User, long) method instead");
        }
        
        public static ListResponse from(Diary diary, com.todayus.entity.User author, long commentCount) {
            return ListResponse.builder()
                    .id(diary.getId())
                    .title(diary.getTitle())
                    .diaryDate(diary.getDiaryDate())
                    .moodEmoji(diary.getMoodEmoji())
                    .imageUrl(diary.getImageUrl())
                    .aiEmotion(diary.getAiEmotion())
                    .aiProcessed(diary.getAiProcessed())
                    .author(UserInfo.from(author))
                    .createdAt(diary.getCreatedAt())
                    .commentCount(commentCount)
                    .build();
        }
    }
    
    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class CommentResponse {
        private Long id;
        private String content;
        private String type;
        private UserInfo author;
        private LocalDateTime createdAt;
        
        public static CommentResponse from(com.todayus.entity.DiaryComment comment) {
            // Note: This method is deprecated, use from(DiaryComment, User) instead
            throw new UnsupportedOperationException("Use from(DiaryComment, User) method instead");
        }
        
        public static CommentResponse from(com.todayus.entity.DiaryComment comment, com.todayus.entity.User author) {
            return CommentResponse.builder()
                    .id(comment.getId())
                    .content(comment.getContent())
                    .type(comment.getType().name())
                    .author(comment.getType() == com.todayus.entity.DiaryComment.CommentType.AI 
                            ? null : UserInfo.from(author))
                    .createdAt(comment.getCreatedAt())
                    .build();
        }
    }
    
    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class UserInfo {
        private Long id;
        private String nickname;
        private String email;
        
        public static UserInfo from(com.todayus.entity.User user) {
            return UserInfo.builder()
                    .id(user.getId())
                    .nickname(user.getNickname())
                    .email(user.getEmail())
                    .build();
        }
    }
    
    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class CommentRequest {
        @NotBlank(message = "댓글 내용은 필수입니다.")
        private String content;
    }
    
    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class EmotionStats {
        private String emotion;
        private long count;
        private double percentage;
        
        public static EmotionStats of(String emotion, long count, long total) {
            return EmotionStats.builder()
                    .emotion(emotion)
                    .count(count)
                    .percentage(total > 0 ? (double) count / total * 100 : 0)
                    .build();
        }
    }
}