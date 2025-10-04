package com.todayus.dto;

import lombok.Builder;
import lombok.Getter;

import java.util.List;

public class StoreDto {

    private StoreDto() {
    }

    @Getter
    @Builder
    public static class RobotSummary {
        private Long id;
        private String code;
        private String name;
        private String tagline;
        private String description;
        private Integer priceOil;
        private String imageUrl;
        private String splashImageUrl;
        private String beforeDiaryImageUrl;
        private String afterDiaryImageUrl;
        private String themeColorHex;
        private String previewMessage;
        private String chatUserGuidance;
        private String commentUserGuidance;
        private Integer chatMaxTokens;
        private Integer commentMaxTokens;
        private Double chatTemperature;
        private Double commentTemperature;
        private boolean owned;
        private boolean active;
    }

    @Getter
    @Builder
    public static class StoreOverview {
        private Integer oilBalance;
        private List<RobotSummary> robots;
    }
}
