package com.todayus.repository;

import com.todayus.entity.Couple;
import com.todayus.entity.User;
import com.todayus.entity.WeeklyFeedback;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface WeeklyFeedbackRepository extends JpaRepository<WeeklyFeedback, Long> {
    
    /**
     * 특정 주에 특정 사용자가 보낸 피드백 조회
     */
    Optional<WeeklyFeedback> findBySenderAndWeekOf(User sender, LocalDate weekOf);
    
    /**
     * 특정 사용자가 받은 읽지 않은 피드백들 조회
     */
    List<WeeklyFeedback> findByReceiverAndIsReadFalseOrderByCreatedAtDesc(User receiver);
    
    /**
     * 특정 커플의 피드백 히스토리 조회 (페이지네이션)
     */
    Page<WeeklyFeedback> findByCoupleOrderByCreatedAtDesc(Couple couple, Pageable pageable);
    
    /**
     * ID-based methods for backward compatibility
     */
    Optional<WeeklyFeedback> findBySenderIdAndWeekOf(Long senderId, LocalDate weekOf);
    List<WeeklyFeedback> findByReceiverIdAndIsReadFalseOrderByCreatedAtDesc(Long receiverId);
    Page<WeeklyFeedback> findByCoupleIdOrderByCreatedAtDesc(Long coupleId, Pageable pageable);
    
    /**
     * AI 처리 대기 중인 피드백들 조회
     */
    @Query("SELECT wf FROM WeeklyFeedback wf WHERE wf.status = 'PENDING' OR wf.status = 'PROCESSING' ORDER BY wf.createdAt ASC")
    List<WeeklyFeedback> findPendingFeedbacks();
    
    /**
     * 특정 기간 동안의 피드백 통계 조회
     */
    @Query("SELECT COUNT(wf) FROM WeeklyFeedback wf WHERE wf.couple = :couple AND wf.weekOf BETWEEN :startDate AND :endDate")
    Long countFeedbacksByDateRange(@Param("couple") Couple couple, 
                                 @Param("startDate") LocalDate startDate, 
                                 @Param("endDate") LocalDate endDate);
    
    /**
     * 특정 사용자가 받은 피드백들 조회 (최신순)
     */
    List<WeeklyFeedback> findByReceiverAndStatusOrderByCreatedAtDesc(User receiver, WeeklyFeedback.FeedbackStatus status);
    
    /**
     * 현재 주에 작성 가능한지 확인을 위한 조회
     */
    @Query("SELECT COUNT(wf) > 0 FROM WeeklyFeedback wf WHERE wf.sender = :sender AND wf.weekOf = :weekOf")
    boolean existsBySenderAndWeekOf(@Param("sender") User sender, @Param("weekOf") LocalDate weekOf);
    
    /**
     * ID-based compatibility methods
     */
    @Query("SELECT COUNT(wf) FROM WeeklyFeedback wf WHERE wf.couple.id = :coupleId AND wf.weekOf BETWEEN :startDate AND :endDate")
    Long countFeedbacksByDateRangeAndCoupleId(@Param("coupleId") Long coupleId, 
                                            @Param("startDate") LocalDate startDate, 
                                            @Param("endDate") LocalDate endDate);
    
    List<WeeklyFeedback> findByReceiverIdAndStatusOrderByCreatedAtDesc(Long receiverId, WeeklyFeedback.FeedbackStatus status);
    
    @Query("SELECT COUNT(wf) > 0 FROM WeeklyFeedback wf WHERE wf.sender.id = :senderId AND wf.weekOf = :weekOf")
    boolean existsBySenderIdAndWeekOf(@Param("senderId") Long senderId, @Param("weekOf") LocalDate weekOf);
}