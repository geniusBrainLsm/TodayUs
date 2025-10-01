package com.todayus.dto;

import com.todayus.entity.Board;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.time.LocalDateTime;

public class BoardDto {

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

        @NotNull(message = "게시판 타입은 필수입니다.")
        private Board.BoardType type;
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
        private Board.BoardType type;
        private Boolean pinned;
        private Integer viewCount;
        private Board.BoardStatus status;
        private AuthorInfo author;
        private LocalDateTime createdAt;
        private LocalDateTime updatedAt;

        public static Response from(Board board) {
            return Response.builder()
                    .id(board.getId())
                    .title(board.getTitle())
                    .content(board.getContent())
                    .type(board.getType())
                    .pinned(board.getPinned())
                    .viewCount(board.getViewCount())
                    .status(board.getStatus())
                    .author(AuthorInfo.from(board.getAuthor()))
                    .createdAt(board.getCreatedAt())
                    .updatedAt(board.getUpdatedAt())
                    .build();
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
        private Board.BoardType type;
        private Boolean pinned;
        private Integer viewCount;
        private AuthorInfo author;
        private LocalDateTime createdAt;

        public static ListResponse from(Board board) {
            return ListResponse.builder()
                    .id(board.getId())
                    .title(board.getTitle())
                    .type(board.getType())
                    .pinned(board.getPinned())
                    .viewCount(board.getViewCount())
                    .author(AuthorInfo.from(board.getAuthor()))
                    .createdAt(board.getCreatedAt())
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
        private String role;

        public static AuthorInfo from(com.todayus.entity.User user) {
            return AuthorInfo.builder()
                    .id(user.getId())
                    .nickname(user.getNickname())
                    .email(user.getEmail())
                    .role(user.getRole().name())
                    .build();
        }
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class AdminUpdateRequest {
        private String title;
        private String content;
        private Boolean pinned;
        private Board.BoardStatus status;
    }
}
