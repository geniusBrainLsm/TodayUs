package com.todayus.service;

import com.todayus.entity.DailyMessage;
import com.todayus.repository.DailyMessageRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.Optional;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class DailyMessageService {

    private final DailyMessageRepository dailyMessageRepository;
    private final AIAnalysisService aiAnalysisService;

    /**
     * 오늘의 일일 메시지 조회 (없으면 생성)
     */
    @Transactional(readOnly = true)
    public String getTodaysMessage() {
        LocalDate today = LocalDate.now();

        Optional<DailyMessage> existingMessage = dailyMessageRepository.findByMessageDate(today);

        if (existingMessage.isPresent()) {
            String message = existingMessage.get().getMessage();
            if (!isFallbackMessage(message, today)) {
                log.info("기존 일일 메시지 조회: {}", today);
                return message;
            }

            dailyMessageRepository.delete(existingMessage.get());
            log.info("기존 기본 메시지를 삭제하고 재생성합니다: {}", today);
        }

        return generateTodaysMessage();
    }


    /**
     * 오늘의 일일 메시지 생성 (AI 사용)
     */
    @Transactional
    public String generateTodaysMessage() {
        LocalDate today = LocalDate.now();

        try {
            log.info("오늘의 일일 메시지 생성 시작: {}", today);

            String generatedMessage = aiAnalysisService.generateDailyMessage();

            DailyMessage dailyMessage = DailyMessage.builder()
                    .messageDate(today)
                    .message(generatedMessage)
                    .build();

            DailyMessage savedMessage = dailyMessageRepository.save(dailyMessage);

            log.info("오늘의 일일 메시지 생성 완료: {} - '{}'", today, generatedMessage);

            return savedMessage.getMessage();

        } catch (Exception e) {
            log.error("일일 메시지 생성 실패: {}", e.getMessage(), e);
            return getFallbackMessage(today);
        }
    }


    /**
     * AI 생성 실패 시 사용할 기본 메시지
     */
    private String getFallbackMessage(LocalDate date) {
        String[] fallbackMessages = {
                "새로운 하루, 새로운 추억을 만들어보세요! ✨",
                "가볍게 손을 잡고 오늘의 작은 순간을 웃으며 시작해요 💫",
                "서로의 마음을 들여다보는 따뜻한 시간으로 하루를 채워보아요 ☕️",
                "소중한 마음을 작은 메시지로 나눠 보는 건 어떨까요? 💌",
                "함께 한다는 사실만으로도 오늘은 충분히 특별해요 🌈"
        };

        // 날짜를 기준으로 메시지 선택 (같은 날에는 같은 메시지)
        int index = date.getDayOfYear() % fallbackMessages.length;
        return fallbackMessages[index];
    }

    private boolean isFallbackMessage(String message, LocalDate date) {
        return message != null && message.equals(getFallbackMessage(date));
    }
}
