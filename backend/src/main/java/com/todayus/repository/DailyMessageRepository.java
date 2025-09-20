package com.todayus.repository;

import com.todayus.entity.DailyMessage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.Optional;

@Repository
public interface DailyMessageRepository extends JpaRepository<DailyMessage, Long> {

    /**
     * 특정 날짜의 일일 메시지 조회
     */
    Optional<DailyMessage> findByMessageDate(LocalDate messageDate);

    /**
     * 가장 최근 일일 메시지 조회
     */
    Optional<DailyMessage> findTopByOrderByMessageDateDesc();
}