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

        // 오늘 메시지가 이미 있는지 확인
        Optional<DailyMessage> existingMessage = dailyMessageRepository.findByMessageDate(today);

        if (existingMessage.isPresent()) {
            log.info("오늘의 일일 메시지 조회: {}", today);
            return existingMessage.get().getMessage();
        }

        // 없으면 새로 생성
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

            // AI로 일일 메시지 생성
            String generatedMessage = aiAnalysisService.generateDailyMessage();

            // DB에 저장
            DailyMessage dailyMessage = DailyMessage.builder()
                    .messageDate(today)
                    .message(generatedMessage)
                    .build();

            DailyMessage savedMessage = dailyMessageRepository.save(dailyMessage);

            log.info("오늘의 일일 메시지 생성 완료: {} - '{}'", today, generatedMessage);

            return savedMessage.getMessage();

        } catch (Exception e) {
            log.error("일일 메시지 생성 실패: {}", e.getMessage(), e);

            // 실패 시 기본 메시지 반환
            String fallbackMessage = getFallbackMessage();

            // 기본 메시지도 저장해서 오늘 중에는 다시 AI 호출하지 않도록
            try {
                DailyMessage fallbackDailyMessage = DailyMessage.builder()
                        .messageDate(today)
                        .message(fallbackMessage)
                        .build();

                dailyMessageRepository.save(fallbackDailyMessage);
            } catch (Exception saveException) {
                log.error("기본 메시지 저장 실패: {}", saveException.getMessage());
            }

            return fallbackMessage;
        }
    }

    /**
     * AI 생성 실패 시 사용할 기본 메시지
     */
    private String getFallbackMessage() {
        String[] fallbackMessages = {
                "새로운 하루, 새로운 추억을 만들어보세요! ✨",
                "오늘도 사랑하는 사람과 함께하는 소중한 하루가 되길 바라요 💕",
                "행복은 함께 나눌 때 더욱 커진다고 해요. 오늘도 행복하세요! 🌟",
                "매일매일이 특별한 기념일이 될 수 있어요. 오늘은 어떤 날로 만들어볼까요? 🎈",
                "작은 것에도 감사하며, 사랑을 나누는 하루가 되시길 바라요 🌸"
        };

        // 날짜를 기준으로 메시지 선택 (같은 날에는 같은 메시지)
        int index = LocalDate.now().getDayOfYear() % fallbackMessages.length;
        return fallbackMessages[index];
    }
}