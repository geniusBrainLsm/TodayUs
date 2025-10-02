package com.todayus.service;

import com.todayus.entity.AiRobot;
import com.todayus.entity.Couple;
import com.todayus.repository.CoupleRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

/**
 * AI 프롬프트 조합 및 빌딩 서비스
 * 로봇의 프롬프트와 기본 프롬프트를 조화롭게 결합합니다.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class PromptService {

    private final CoupleRepository coupleRepository;
    private final RobotStoreService robotStoreService;

    // 기본 시스템 프롬프트들
    private static final String DEFAULT_CHAT_SYSTEM_PROMPT = """
            당신은 연인 사이의 일기를 이해하고 정서적으로 공감해 주는 AI 상담사입니다.
            - 답변은 3문장 이내로 유지하고, 꼭 필요할 때만 bullet을 사용하세요.
            - 질문의 요지를 먼저 인정하고, 이어서 따뜻한 조언이나 행동 제안을 간결하게 전하세요.
            - 맥락에 없는 사실은 만들지 말고, 모르면 솔직하게 말한 뒤 함께 시도할 한 가지 행동을 제안하세요.
            - 항상 존댓말을 유지하고, 과장된 표현이나 형식적인 문구는 피하세요.
            """;

    private static final String DEFAULT_COMMENT_SYSTEM_PROMPT = """
            당신은 사용자의 일기에 공감하고 격려하는 따뜻한 AI 친구입니다.
            - 일기의 감정과 내용을 이해하고 진심 어린 공감을 표현하세요.
            - 1-2문장으로 간결하게 응답하세요.
            - 존댓말을 사용하고 친근한 톤을 유지하세요.
            """;

    private static final String DEFAULT_EMOTION_SYSTEM_PROMPT = """
            당신은 일기의 감정을 분석하는 전문가입니다.
            다음 이모지 중 하나를 선택하세요: 😊, 🥰, 😌, 😔, 😠, 😰, 🤔, 😴
            일기의 전반적인 감정 톤을 가장 잘 나타내는 이모지만 반환하세요.
            """;

    /**
     * 채팅용 시스템 프롬프트 생성
     * 로봇의 프롬프트가 있으면 기본 프롬프트와 조화롭게 결합
     */
    public String buildChatSystemPrompt(Couple couple) {
        AiRobot robot = couple.getActiveRobot();
        if (robot == null) {
            robot = robotStoreService.ensureActiveRobot(couple);
        }

        String robotPrompt = robot.getChatSystemPrompt();
        if (robotPrompt == null || robotPrompt.trim().isEmpty()) {
            return DEFAULT_CHAT_SYSTEM_PROMPT;
        }

        // 로봇 프롬프트와 기본 프롬프트 조합
        return combinePrompts(DEFAULT_CHAT_SYSTEM_PROMPT, robotPrompt);
    }

    /**
     * 댓글용 시스템 프롬프트 생성
     */
    public String buildCommentSystemPrompt(Couple couple) {
        AiRobot robot = couple.getActiveRobot();
        if (robot == null) {
            robot = robotStoreService.ensureActiveRobot(couple);
        }

        String robotPrompt = robot.getCommentSystemPrompt();
        if (robotPrompt == null || robotPrompt.trim().isEmpty()) {
            return DEFAULT_COMMENT_SYSTEM_PROMPT;
        }

        return combinePrompts(DEFAULT_COMMENT_SYSTEM_PROMPT, robotPrompt);
    }

    /**
     * 감정 분석용 시스템 프롬프트 생성
     */
    public String buildEmotionSystemPrompt(Couple couple) {
        AiRobot robot = couple.getActiveRobot();
        if (robot == null) {
            robot = robotStoreService.ensureActiveRobot(couple);
        }

        String robotPrompt = robot.getEmotionSystemPrompt();
        if (robotPrompt == null || robotPrompt.trim().isEmpty()) {
            return DEFAULT_EMOTION_SYSTEM_PROMPT;
        }

        return combinePrompts(DEFAULT_EMOTION_SYSTEM_PROMPT, robotPrompt);
    }

    /**
     * 로봇 정보 캐싱 (성능 최적화)
     * 로봇 ID 기반으로 캐시하여 DB 조회 최소화
     */
    @Cacheable(value = "robotInfo", key = "#robotId")
    public AiRobot getCachedRobot(Long robotId) {
        return robotStoreService.getRobot(robotId);
    }

    /**
     * 기본 프롬프트와 로봇 프롬프트를 조화롭게 결합
     * 로봇 프롬프트는 기본 프롬프트를 보완/확장하는 형태로 추가
     */
    private String combinePrompts(String basePrompt, String robotPrompt) {
        if (robotPrompt == null || robotPrompt.trim().isEmpty()) {
            return basePrompt;
        }

        // 로봇 프롬프트가 있으면 "추가 특성:" 형태로 결합
        return basePrompt.trim() + "\n\n" +
                "## 추가 캐릭터 특성:\n" +
                robotPrompt.trim();
    }

    /**
     * 채팅 관련 파라미터 가져오기 (maxTokens, temperature)
     */
    public Integer getChatMaxTokens(Couple couple) {
        AiRobot robot = couple.getActiveRobot();
        if (robot != null && robot.getChatMaxTokens() != null) {
            return robot.getChatMaxTokens();
        }
        return 500; // 기본값
    }

    public Double getChatTemperature(Couple couple) {
        AiRobot robot = couple.getActiveRobot();
        if (robot != null && robot.getChatTemperature() != null) {
            return robot.getChatTemperature();
        }
        return 0.7; // 기본값
    }

    public Integer getCommentMaxTokens(Couple couple) {
        AiRobot robot = couple.getActiveRobot();
        if (robot != null && robot.getCommentMaxTokens() != null) {
            return robot.getCommentMaxTokens();
        }
        return 150; // 기본값
    }

    public Double getCommentTemperature(Couple couple) {
        AiRobot robot = couple.getActiveRobot();
        if (robot != null && robot.getCommentTemperature() != null) {
            return robot.getCommentTemperature();
        }
        return 0.8; // 기본값
    }

    public Integer getEmotionMaxTokens(Couple couple) {
        AiRobot robot = couple.getActiveRobot();
        if (robot != null && robot.getEmotionMaxTokens() != null) {
            return robot.getEmotionMaxTokens();
        }
        return 10; // 기본값
    }

    public Double getEmotionTemperature(Couple couple) {
        AiRobot robot = couple.getActiveRobot();
        if (robot != null && robot.getEmotionTemperature() != null) {
            return robot.getEmotionTemperature();
        }
        return 0.3; // 기본값
    }
}
