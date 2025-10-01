package com.todayus.dto;

import com.todayus.entity.BoardComment;
import jakarta.validation.constraints.NotBlank;
import lombok.*;

import java.time.LocalDateTime;

public class BoardCommentDto {

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class CreateRequest {
        @NotBlank(message = "댓글 내용은 필수입니다.")
        private String content;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class UpdateRequest {
        @NotBlank(message = "댓글 내용은 필수입니다.")
        private String content;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class Response {
        private Long id;
        private Long boardId;
        private String content;
        private AuthorInfo author;
        private BoardComment.CommentStatus status;
        private LocalDateTime createdAt;
        private LocalDateTime updatedAt;

        public static Response from(BoardComment comment) {
            return Response.builder()
                    .id(comment.getId())
                    .boardId(comment.getBoard().getId())
                    .content(comment.getContent())
                    .author(AuthorInfo.from(comment.getAuthor()))
                    .status(comment.getStatus())
                    .createdAt(comment.getCreatedAt())
                    .updatedAt(comment.getUpdatedAt())
                    .build();
        }
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class AuthorInfo {
        private Long id;
        private String nickname;
        private String email;

        public static AuthorInfo from(com.todayus.entity.User user) {
            return AuthorInfo.builder()
                    .id(user.getId())
                    .nickname(user.getNickname())
                    .email(user.getEmail())
                    .build();
        }
    }
}
