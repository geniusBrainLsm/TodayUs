package com.todayus.repository;

import com.todayus.entity.Couple;
import com.todayus.entity.CoupleSummary;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.Optional;

@Repository
public interface CoupleSummaryRepository extends JpaRepository<CoupleSummary, Long> {

    /**
     * 특정 커플의 특정 날짜 요약 조회
     */
    Optional<CoupleSummary> findByCoupleAndSummaryDate(Couple couple, LocalDate summaryDate);

    /**
     * 특정 커플의 가장 최근 요약 조회
     */
    Optional<CoupleSummary> findTopByCoupleOrderBySummaryDateDesc(Couple couple);
}