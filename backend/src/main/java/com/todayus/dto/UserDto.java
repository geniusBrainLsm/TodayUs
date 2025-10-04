package com.todayus.dto;

import com.todayus.entity.AiRobot;
import com.todayus.entity.Couple;
import com.todayus.entity.User;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserDto {

    private Long id;
    private String email;
    private String name;
    private String nickname;
    private Boolean nicknameSet;
    private String profileImageUrl;
    private User.Provider provider;
    private User.Role role;
    private LocalDateTime createdAt;

    // Active Robot Info
    private Integer oilBalance;
    private String activeRobotName;
    private String activeRobotImageUrl;
    private String activeRobotSplashImageUrl;
    private String activeRobotBeforeDiaryImageUrl;
    private String activeRobotAfterDiaryImageUrl;
    private String activeRobotThemeColorHex;
    private String activeRobotPreviewMessage;

    public static UserDto from(User user) {
        return UserDto.builder()
                .id(user.getId())
                .email(user.getEmail())
                .name(user.getName())
                .nickname(user.getNickname())
                .nicknameSet(user.getNicknameSet())
                .profileImageUrl(user.getProfileImageUrl())
                .provider(user.getProvider())
                .role(user.getRole())
                .createdAt(user.getCreatedAt())
                .build();
    }

    public static UserDto fromWithCouple(User user, Couple couple) {
        UserDtoBuilder builder = UserDto.builder()
                .id(user.getId())
                .email(user.getEmail())
                .name(user.getName())
                .nickname(user.getNickname())
                .nicknameSet(user.getNicknameSet())
                .profileImageUrl(user.getProfileImageUrl())
                .provider(user.getProvider())
                .role(user.getRole())
                .createdAt(user.getCreatedAt());

        if (couple != null) {
            builder.oilBalance(couple.getOilBalance());
            AiRobot activeRobot = couple.getActiveRobot();
            if (activeRobot != null) {
                builder.activeRobotName(activeRobot.getName())
                       .activeRobotImageUrl(activeRobot.getImageUrl())
                       .activeRobotSplashImageUrl(activeRobot.getSplashImageUrl())
                       .activeRobotBeforeDiaryImageUrl(activeRobot.getBeforeDiaryImageUrl())
                       .activeRobotAfterDiaryImageUrl(activeRobot.getAfterDiaryImageUrl())
                       .activeRobotThemeColorHex(activeRobot.getThemeColorHex())
                       .activeRobotPreviewMessage(activeRobot.getPreviewMessage());
            }
        }

        return builder.build();
    }
}
