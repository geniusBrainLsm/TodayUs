package com.todayus.service;

import com.todayus.entity.Couple;
import com.todayus.entity.CoupleSummary;
import com.todayus.entity.Diary;
import com.todayus.repository.CoupleSummaryRepository;
import com.todayus.repository.DiaryRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class CoupleSummaryService {

    private final CoupleSummaryRepository coupleSummaryRepository;
    private final DiaryRepository diaryRepository;
    private final AIAnalysisService aiAnalysisService;

    /**
     * 오늘의 커플 요약 조회 (없으면 생성)
     */
    @Transactional(readOnly = true)
    public String getTodaysCoupleSummary(Couple couple) {
        LocalDate today = LocalDate.now();

        Optional<CoupleSummary> existingSummary = coupleSummaryRepository.findByCoupleAndSummaryDate(couple, today);

        if (existingSummary.isPresent()) {
            String summary = existingSummary.get().getSummary();
            if (!isFallbackSummary(summary, today)) {
                log.info("기존 커플 요약 조회: {} - couple: {}", today, couple.getId());
                return summary;
            }

            coupleSummaryRepository.delete(existingSummary.get());
            log.info("기존 기본 커플 요약을 삭제하고 재생성합니다: {} - couple: {}", today, couple.getId());
        }

        return generateTodaysCoupleSummary(couple);
    }


    /**
     * 오늘의 커플 요약 생성 (AI 사용)
     */
    @Transactional
    public String generateTodaysCoupleSummary(Couple couple) {
        LocalDate today = LocalDate.now();

        try {
            log.info("오늘의 커플 요약 생성 시작: {} - couple: {}", today, couple.getId());

            Pageable pageable = PageRequest.of(0, 10);
            List<Diary> recentDiaries = diaryRepository.findRecentByCoupleOrderByCreatedAtDesc(couple, pageable);

            String generatedSummary = aiAnalysisService.generateCoupleSummary(recentDiaries);

            CoupleSummary coupleSummary = CoupleSummary.builder()
                    .couple(couple)
                    .summaryDate(today)
                    .summary(generatedSummary)
                    .build();

            CoupleSummary savedSummary = coupleSummaryRepository.save(coupleSummary);

            log.info("오늘의 커플 요약 생성 완료: {} - couple: {} - '{}'", today, couple.getId(), generatedSummary);

            return savedSummary.getSummary();

        } catch (Exception e) {
            log.error("커플 요약 생성 실패: couple: {} - {}", couple.getId(), e.getMessage(), e);
            return getFallbackSummary(today);
        }
    }


    /**
     * AI 생성 실패 시 사용할 기본 커플 요약
     */
    private String getFallbackSummary(LocalDate date) {
        String[] fallbackSummaries = {
                "서로를 향한 마음이
일기 속에 따뜻하게
담겨있는 소중한 시간 💕",
                "함께 나눈 일상의 순간이
더 큰 사랑으로 이어지고 있어요 ✨",
                "서로를 위한 마음이
매일 조금씩 쌓이며
따뜻한 추억을 만들고 있어요 ☕️",
                "두 사람이 걸어온 발걸음이
오늘도 서로에게 힘이 되고 있어요 🌿",
                "진심 어린 마음이
일기 속에 고스란히 담겨 있어요
서로를 향한 응원을 이어가요 🌈"
        };

        // 날짜를 기준으로 메시지 선택 (같은 날에는 같은 메시지)
        int index = date.getDayOfYear() % fallbackSummaries.length;
        return fallbackSummaries[index];
    }
}
