package com.todayus.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;
import java.util.List;

public class AiChatDto {

    @Getter
    @Setter
    @NoArgsConstructor
    public static class Request {

        @NotBlank(message = "메시지를 입력해 주세요.")
        private String message;

        public Request(String message) {
            this.message = message;
        }
    }

    @Getter
    @Builder
    @AllArgsConstructor
    public static class Response {
        private final String reply;
        private final List<DiarySnippet> references;
    }

    @Getter
    @Builder
    @AllArgsConstructor
    public static class DiarySnippet {
        private final Long diaryId;
        private final LocalDate diaryDate;
        private final String title;
        private final String moodEmoji;
        private final String summary;
    }
}

