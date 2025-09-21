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
                String.join("\n",
                        "\uC11C\uB85C\uB97C \uD5A5\uD55C \uB9C8\uC74C\uC774",
                        "\uC77C\uAE30 \uC18D\uC5D0 \uB530\uB77C\uD558\uAC8C",
                        "\uB2F4\uACA8\uC788\uB294 \uC18C\uC911\uD55C \uC2DC\uAC04 \uD83D\uDC95"
                ),
                String.join("\n",
                        "\uD568\uAED8 \uB098\uB204\uB294 \uC77C\uC0C1\uC758 \uC21C\uAC04\uC774",
                        "\uB354 \uD070 \uC0AC\uB791\uC73C\uB85C \uC774\uC5B4\uC9C0\uACE0 \uC788\uC5B4\uC694 \u2728"
                ),
                String.join("\n",
                        "\uC11C\uB85C\uB97C \uC704\uD55C \uB9C8\uC74C\uC774",
                        "\uB9E4\uC77C \uC870\uAE08\uC529 \uC313\uC774\uBA70",
                        "\uB530\uB77C\uD55C \uCD94\uC5B5\uC744 \uB9CC\uB4DC\uACE0 \uC788\uC5B4\uC694 \u2615\uFE0F"
                ),
                String.join("\n",
                        "\uB450 \uC0AC\uB78C\uC774 \uAC78\uC5B4\uC628 \uBC1C\uAC00\uB77C\uC74C\uC774",
                        "\uC624\uB298\uB3C4 \uC11C\uB85C\uC5D0\uAC8C \uD798\uC774 \uB418\uACE0 \uC788\uC5B4\uC694 \uD83C\uDF3F"
                ),
                String.join("\n",
                        "\uC9C4\uC2EC \uC5B4\uB9B0 \uB9C8\uC74C\uC774",
                        "\uC77C\uAE30 \uC18D\uC5D0 \uACE0\uC2A4\uB780\uD788 \uB2F4\uACA8 \uC788\uC5B4\uC694",
                        "\uC11C\uB85C\uB97C \uD5A5\uD55C \uC751\uC6D0\uC744 \uC774\uC5B4\uAC00\uC694 \uD83C\uDF08"
                )
        };


        // 날짜를 기준으로 메시지 선택 (같은 날에는 같은 메시지)
        int index = date.getDayOfYear() % fallbackSummaries.length;
        return fallbackSummaries[index];
    }

    /**
     * 주어진 요약이 폴백 요약인지 확인
     */
    private boolean isFallbackSummary(String summary, LocalDate date) {
        if (summary == null || summary.trim().isEmpty()) {
            return true;
        }

        String fallbackSummary = getFallbackSummary(date);
        return summary.trim().equals(fallbackSummary.trim());
    }
}
