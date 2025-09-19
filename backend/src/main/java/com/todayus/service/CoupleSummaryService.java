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

        // 오늘 요약이 이미 있는지 확인
        Optional<CoupleSummary> existingSummary = coupleSummaryRepository.findByCoupleAndSummaryDate(couple, today);

        if (existingSummary.isPresent()) {
            log.info("오늘의 커플 요약 조회: {} - couple: {}", today, couple.getId());
            return existingSummary.get().getSummary();
        }

        // 없으면 새로 생성
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

            // 최근 10개 일기 조회
            Pageable pageable = PageRequest.of(0, 10);
            List<Diary> recentDiaries = diaryRepository.findRecentByCoupleOrderByCreatedAtDesc(couple, pageable);

            // AI로 커플 요약 생성
            String generatedSummary = aiAnalysisService.generateCoupleSummary(recentDiaries);

            // DB에 저장
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

            // 실패 시 기본 메시지 반환
            String fallbackSummary = getFallbackSummary();

            // 기본 메시지도 저장해서 오늘 중에는 다시 AI 호출하지 않도록
            try {
                CoupleSummary fallbackCoupleSummary = CoupleSummary.builder()
                        .couple(couple)
                        .summaryDate(today)
                        .summary(fallbackSummary)
                        .build();

                coupleSummaryRepository.save(fallbackCoupleSummary);
            } catch (Exception saveException) {
                log.error("기본 커플 요약 저장 실패: couple: {} - {}", couple.getId(), saveException.getMessage());
            }

            return fallbackSummary;
        }
    }

    /**
     * AI 생성 실패 시 사용할 기본 커플 요약
     */
    private String getFallbackSummary() {
        String[] fallbackSummaries = {
                "서로를 향한 마음이\n일기 속에 따뜻하게\n담겨있는 소중한 시간 💕",
                "함께 나누는 일상이\n더욱 특별하고 아름답게\n기록되고 있어요 ✨",
                "사랑하는 마음으로\n매일매일을 함께\n만들어가고 있네요 🌸",
                "두 사람의 이야기가\n하루하루 소중한 추억으로\n쌓여가고 있어요 🌟",
                "진심 어린 마음들이\n일기를 통해 전해지는\n아름다운 시간이에요 💖"
        };

        // 날짜를 기준으로 메시지 선택 (같은 날에는 같은 메시지)
        int index = LocalDate.now().getDayOfYear() % fallbackSummaries.length;
        return fallbackSummaries[index];
    }
}