package com.todayus.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PastOrPresent;
import java.time.LocalDate;

public class AnniversaryDto {
    
    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class Request {
        @NotNull(message = "기념일 날짜는 필수입니다.")
        @PastOrPresent(message = "기념일은 현재 날짜 이전이어야 합니다.")
        private LocalDate anniversaryDate;
    }
    
    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class Response {
        private LocalDate anniversaryDate;
        private Long daysSince;
        private String formattedDate;
        private String daysDisplay;
        private Boolean canEdit;
        private String setterName;
        
        public static Response from(LocalDate anniversaryDate, Long daysSince) {
            return Response.builder()
                    .anniversaryDate(anniversaryDate)
                    .daysSince(daysSince)
                    .formattedDate(formatDate(anniversaryDate))
                    .daysDisplay(daysSince != null ? "D+" + daysSince : null)
                    .build();
        }
        
        private static String formatDate(LocalDate date) {
            if (date == null) return null;
            
            String[] months = {
                "1월", "2월", "3월", "4월", "5월", "6월",
                "7월", "8월", "9월", "10월", "11월", "12월"
            };
            
            return date.getYear() + "년 " + 
                   months[date.getMonthValue() - 1] + " " + 
                   date.getDayOfMonth() + "일";
        }
    }
}