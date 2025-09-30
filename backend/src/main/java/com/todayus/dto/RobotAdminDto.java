package com.todayus.dto;

import com.todayus.entity.AiRobot;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

public class RobotAdminDto {

    private RobotAdminDto() {
    }

    @Getter
    @Builder
    public static class Response {
        private Long id;
        private String code;
        private String name;
        private String tagline;
        private String description;
        private Integer priceOil;
        private String imageUrl;
        private String splashImageUrl;
        private String themeColorHex;
        private String previewMessage;
        private String chatSystemPrompt;
        private String chatUserGuidance;
        private Integer chatMaxTokens;
        private Double chatTemperature;
        private String commentSystemPrompt;
        private String commentUserGuidance;
        private Integer commentMaxTokens;
        private Double commentTemperature;
        private String emotionSystemPrompt;
        private Integer emotionMaxTokens;
        private Double emotionTemperature;
        private Boolean defaultRobot;
        private Boolean active;
        private Integer displayOrder;

        public static Response from(AiRobot robot) {
            return Response.builder()
                    .id(robot.getId())
                    .code(robot.getCode())
                    .name(robot.getName())
                    .tagline(robot.getTagline())
                    .description(robot.getDescription())
                    .priceOil(robot.getPriceOil())
                    .imageUrl(robot.getImageUrl())
                    .splashImageUrl(robot.getSplashImageUrl())
                    .themeColorHex(robot.getThemeColorHex())
                    .previewMessage(robot.getPreviewMessage())
                    .chatSystemPrompt(robot.getChatSystemPrompt())
                    .chatUserGuidance(robot.getChatUserGuidance())
                    .chatMaxTokens(robot.getChatMaxTokens())
                    .chatTemperature(robot.getChatTemperature())
                    .commentSystemPrompt(robot.getCommentSystemPrompt())
                    .commentUserGuidance(robot.getCommentUserGuidance())
                    .commentMaxTokens(robot.getCommentMaxTokens())
                    .commentTemperature(robot.getCommentTemperature())
                    .emotionSystemPrompt(robot.getEmotionSystemPrompt())
                    .emotionMaxTokens(robot.getEmotionMaxTokens())
                    .emotionTemperature(robot.getEmotionTemperature())
                    .defaultRobot(robot.getDefaultRobot())
                    .active(robot.getActive())
                    .displayOrder(robot.getDisplayOrder())
                    .build();
        }
    }

    @Getter
    @Setter
    @NoArgsConstructor
    public static class Request {
        private String code;
        private String name;
        private String tagline;
        private String description;
        private Integer priceOil;
        private String imageUrl;
        private String splashImageUrl;
        private String themeColorHex;
        private String previewMessage;
        private String chatSystemPrompt;
        private String chatUserGuidance;
        private Integer chatMaxTokens;
        private Double chatTemperature;
        private String commentSystemPrompt;
        private String commentUserGuidance;
        private Integer commentMaxTokens;
        private Double commentTemperature;
        private String emotionSystemPrompt;
        private Integer emotionMaxTokens;
        private Double emotionTemperature;
        private Boolean defaultRobot;
        private Boolean active;
        private Integer displayOrder;

        public AiRobot toEntity() {
            return AiRobot.builder()
                    .code(code)
                    .name(name)
                    .tagline(tagline)
                    .description(description)
                    .priceOil(priceOil != null ? priceOil : 0)
                    .imageUrl(imageUrl)
                    .splashImageUrl(splashImageUrl)
                    .themeColorHex(themeColorHex)
                    .previewMessage(previewMessage)
                    .chatSystemPrompt(chatSystemPrompt)
                    .chatUserGuidance(chatUserGuidance)
                    .chatMaxTokens(chatMaxTokens)
                    .chatTemperature(chatTemperature)
                    .commentSystemPrompt(commentSystemPrompt)
                    .commentUserGuidance(commentUserGuidance)
                    .commentMaxTokens(commentMaxTokens)
                    .commentTemperature(commentTemperature)
                    .emotionSystemPrompt(emotionSystemPrompt)
                    .emotionMaxTokens(emotionMaxTokens)
                    .emotionTemperature(emotionTemperature)
                    .defaultRobot(defaultRobot != null && defaultRobot)
                    .active(active != null ? active : Boolean.TRUE)
                    .displayOrder(displayOrder != null ? displayOrder : 0)
                    .build();
        }
    }
}
