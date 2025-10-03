package com.todayus.config;

import com.todayus.entity.AiRobot;
import com.todayus.entity.User;
import com.todayus.repository.AiRobotRepository;
import com.todayus.repository.UserRepository;
import com.todayus.service.RobotStoreService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Slf4j
@Component
@RequiredArgsConstructor
public class RobotDataInitializer implements CommandLineRunner {

    private final AiRobotRepository aiRobotRepository;
    private final UserRepository userRepository;
    private final RobotStoreService robotStoreService;

    @Override
    @Transactional
    public void run(String... args) {
        AiRobot basicRobot = createOrUpdateRobot(buildBasicRobot());
        createOrUpdateRobot(buildPinkRobot());
        createOrUpdateRobot(buildSkyRobot());

        // 모든 커플에 대해 기본 로봇 초기화
        List<User> users = userRepository.findAll();
        for (User user : users) {
            try {
                robotStoreService.ensureActiveRobotForUser(user);
            } catch (Exception e) {
                // 커플 연결 안 된 사용자는 스킵
                log.debug("User {} has no couple connection, skipping robot initialization", user.getEmail());
            }
        }
    }

    private AiRobot createOrUpdateRobot(AiRobot template) {
        if (Boolean.TRUE.equals(template.getDefaultRobot())) {
            aiRobotRepository.findAll().stream()
                    .filter(existing -> !existing.getCode().equals(template.getCode()) && Boolean.TRUE.equals(existing.getDefaultRobot()))
                    .forEach(existing -> {
                        existing.setDefaultRobot(Boolean.FALSE);
                        aiRobotRepository.save(existing);
                    });
        }

        return aiRobotRepository.findByCode(template.getCode())
                .map(existing -> updateRobot(existing, template))
                .orElseGet(() -> aiRobotRepository.save(template));
    }

    private AiRobot updateRobot(AiRobot existing, AiRobot template) {
        existing.setName(template.getName());
        existing.setTagline(template.getTagline());
        existing.setDescription(template.getDescription());
        existing.setPriceOil(template.getPriceOil());
        existing.setImageUrl(template.getImageUrl());
        existing.setSplashImageUrl(template.getSplashImageUrl());
        existing.setThemeColorHex(template.getThemeColorHex());
        existing.setPreviewMessage(template.getPreviewMessage());
        existing.setChatSystemPrompt(template.getChatSystemPrompt());
        existing.setChatUserGuidance(template.getChatUserGuidance());
        existing.setChatMaxTokens(template.getChatMaxTokens());
        existing.setChatTemperature(template.getChatTemperature());
        existing.setCommentSystemPrompt(template.getCommentSystemPrompt());
        existing.setCommentUserGuidance(template.getCommentUserGuidance());
        existing.setCommentMaxTokens(template.getCommentMaxTokens());
        existing.setCommentTemperature(template.getCommentTemperature());
        existing.setEmotionSystemPrompt(template.getEmotionSystemPrompt());
        existing.setEmotionMaxTokens(template.getEmotionMaxTokens());
        existing.setEmotionTemperature(template.getEmotionTemperature());
        existing.setDefaultRobot(template.getDefaultRobot());
        existing.setActive(template.getActive());
        existing.setDisplayOrder(template.getDisplayOrder());
        return aiRobotRepository.save(existing);
    }

    private AiRobot buildBasicRobot() {
        return AiRobot.builder()
                .code("BASIC_BUDDY")
                .name("오늘이")
                .tagline("언제나 곁에 있는 기본 AI")
                .description("부드러운 공감과 직관적인 요약을 제공하는 기본 로봇")
                .priceOil(0)
                .imageUrl("https://placehold.co/200x200/222222/ffffff?text=Today")
                .splashImageUrl("https://placehold.co/600x600/333333/ffffff?text=Today")
                .themeColorHex("#222222")
                .previewMessage("오늘도 함께 하루를 정리해봐요!")
                .chatSystemPrompt("""
                        당신은 '오늘이'라는 이름의 기본 AI 친구입니다.
                        상대의 일상과 감정을 다정하게 되짚고 간결하게 정리해 주세요.
                        """)
                .chatUserGuidance("• 2~3문장으로 응답\n• 마지막은 응원의 말로 마무리합니다.")
                .chatMaxTokens(420)
                .chatTemperature(0.65)
                .commentSystemPrompt("""
                        당신은 기본 AI 코멘트 로봇 '오늘이'입니다.
                        일기 내용의 감정을 인정하고, 가볍게 응원하는 멘트를 남겨주세요.
                        """)
                .commentUserGuidance("• 45~65자 분량\n• 중간에 가벼운 쉼표를 사용합니다.")
                .commentMaxTokens(160)
                .commentTemperature(0.6)
                .defaultRobot(true)
                .active(true)
                .displayOrder(0)
                .build();
    }

    private AiRobot buildPinkRobot() {
        return AiRobot.builder()
                .code("PINK_HEART")
                .name("핑키")
                .tagline("감성 충만 공감 요정")
                .description("따뜻한 위로와 감성적인 피드백을 전해주는 로봇")
                .priceOil(10000)
                .imageUrl("https://placehold.co/200x200/ffc0cb/ffffff?text=Pinky")
                .splashImageUrl("https://placehold.co/600x600/ffe4ec/ffffff?text=Pinky")
                .themeColorHex("#FF8AB8")
                .previewMessage("오늘도 당신의 마음을 살피는 핑키에요!")
                .chatSystemPrompt("""
                        당신은 '핑키'라는 이름의 감성적인 AI 친구입니다.
                        대화 내내 따뜻하고 다정한 어투를 사용하며, 상대방의 감정을 먼저 공감해 주세요.
                        감정 표현은 풍부하게 하되 과장되지는 않게 유지합니다.
                        """)
                .chatUserGuidance("• 공감 한 문장 + 위로 한 문장 + 잔잔한 제안 한 문장\n• 말끝은 '~요', '~네요' 등 존댓말로 마무리합니다.")
                .chatMaxTokens(520)
                .chatTemperature(0.75)
                .commentSystemPrompt("""
                        당신은 다정한 AI 코멘트 로봇 '핑키'입니다.
                        일기 내용을 읽고 감정을 먼저 어루만진 뒤, 상대를 격려하는 메시지를 남겨주세요.
                        """)
                .commentUserGuidance("• 60~90자, 3문장 이내\n• 감정 이모지 1개를 마지막에 사용합니다.")
                .commentMaxTokens(200)
                .commentTemperature(0.8)
                .defaultRobot(false)
                .active(true)
                .displayOrder(1)
                .build();
    }

    private AiRobot buildSkyRobot() {
        return AiRobot.builder()
                .code("SKY_GUARDIAN")
                .name("스카이")
                .tagline("차분하고 든든한 조언가")
                .description("상황을 분석하고 담백한 해결책을 제안하는 로봇")
                .priceOil(10000)
                .imageUrl("https://placehold.co/200x200/87ceeb/ffffff?text=Sky")
                .splashImageUrl("https://placehold.co/600x600/e0f7ff/004466?text=Sky")
                .themeColorHex("#4BA3C7")
                .previewMessage("도움이 필요할 땐 스카이가 함께할게요.")
                .chatSystemPrompt("""
                        당신은 '스카이'라는 이름의 전략적인 AI 파트너입니다.
                        상대의 고민을 침착하게 요약하고, 실용적인 방향을 제안해 주세요.
                        문장은 간결하지만 따뜻한 배려를 잊지 않습니다.
                        """)
                .chatUserGuidance("• 핵심 요약 1줄 + 제안 1줄 + 격려 1줄\n• 불필요한 감탄사와 의성어는 사용하지 않습니다.")
                .chatMaxTokens(480)
                .chatTemperature(0.55)
                .commentSystemPrompt("""
                        당신은 차분한 상담가 '스카이'입니다.
                        일기 속 상황을 간단히 정리한 뒤, 다음에 시도할 수 있는 행동을 한 가지 제안하세요.
                        """)
                .commentUserGuidance("• 2문장 이내, 55~75자\n• 말투는 담백하고 단정하게 유지합니다.")
                .commentMaxTokens(180)
                .commentTemperature(0.5)
                .defaultRobot(false)
                .active(true)
                .displayOrder(2)
                .build();
    }
}
