package com.todayus.repository;

import com.todayus.entity.Couple;
import com.todayus.entity.Diary;
import com.todayus.entity.User;
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
public interface DiaryRepository extends JpaRepository<Diary, Long> {
    
    @Query("SELECT d FROM Diary d WHERE d.couple = :couple AND d.status = 'PUBLISHED' ORDER BY d.diaryDate ASC, d.createdAt ASC")
    List<Diary> findByCoupleOrderByDiaryDateAsc(@Param("couple") Couple couple);

    // Find diaries by couple (both users can see each other's diaries)
    @Query("SELECT d FROM Diary d WHERE d.couple = :couple AND d.status = 'PUBLISHED' ORDER BY d.diaryDate DESC, d.createdAt DESC")
    Page<Diary> findByCoupleOrderByDiaryDateDescCreatedAtDesc(@Param("couple") Couple couple, Pageable pageable);
    
    // Find diaries by user
    @Query("SELECT d FROM Diary d WHERE d.user = :user AND d.status = 'PUBLISHED' ORDER BY d.diaryDate DESC, d.createdAt DESC")
    Page<Diary> findByUserOrderByDiaryDateDescCreatedAtDesc(@Param("user") User user, Pageable pageable);
    
    // Find diary by user and date
    Optional<Diary> findByUserAndDiaryDate(User user, LocalDate diaryDate);
    
    // ID-based methods for backward compatibility
    @Query("SELECT d FROM Diary d WHERE d.couple.id = :coupleId AND d.status = 'PUBLISHED' ORDER BY d.diaryDate DESC, d.createdAt DESC")
    Page<Diary> findByCoupleIdOrderByDiaryDateDescCreatedAtDesc(@Param("coupleId") Long coupleId, Pageable pageable);
    @Query("SELECT d FROM Diary d WHERE d.user.id = :userId AND d.status = 'PUBLISHED' ORDER BY d.diaryDate DESC, d.createdAt DESC")
    Page<Diary> findByUserIdOrderByDiaryDateDescCreatedAtDesc(@Param("userId") Long userId, Pageable pageable);
    Optional<Diary> findByUserIdAndDiaryDate(Long userId, LocalDate diaryDate);
    
    // Find diaries by couple and date range
    @Query("SELECT d FROM Diary d WHERE d.couple = :couple AND d.status = 'PUBLISHED' AND d.diaryDate BETWEEN :startDate AND :endDate ORDER BY d.diaryDate DESC, d.createdAt DESC")
    List<Diary> findByCoupleAndDateRange(@Param("couple") Couple couple, 
                                        @Param("startDate") LocalDate startDate, 
                                        @Param("endDate") LocalDate endDate);
    
    // Find diaries by couple and date range (for weekly summary)
    @Query("SELECT d FROM Diary d WHERE d.couple = :couple AND d.status = 'PUBLISHED' AND d.diaryDate BETWEEN :startDate AND :endDate ORDER BY d.diaryDate DESC")
    List<Diary> findByCoupleAndDiaryDateBetweenOrderByDiaryDateDesc(@Param("couple") Couple couple, @Param("startDate") LocalDate startDate, @Param("endDate") LocalDate endDate);
    
    // ID-based methods for backward compatibility
    @Query("SELECT d FROM Diary d WHERE d.couple.id = :coupleId AND d.status = 'PUBLISHED' AND d.diaryDate BETWEEN :startDate AND :endDate ORDER BY d.diaryDate DESC, d.createdAt DESC")
    List<Diary> findByCoupleIdAndDateRange(@Param("coupleId") Long coupleId, 
                                          @Param("startDate") LocalDate startDate, 
                                          @Param("endDate") LocalDate endDate);
    @Query("SELECT d FROM Diary d WHERE d.couple.id = :coupleId AND d.status = 'PUBLISHED' AND d.diaryDate BETWEEN :startDate AND :endDate ORDER BY d.diaryDate DESC")
    List<Diary> findByCoupleIdAndDiaryDateBetweenOrderByDiaryDateDesc(@Param("coupleId") Long coupleId, @Param("startDate") LocalDate startDate, @Param("endDate") LocalDate endDate);
    
    // Find recent diaries by couple
    @Query("SELECT d FROM Diary d WHERE d.couple = :couple AND d.status = 'PUBLISHED' ORDER BY d.createdAt DESC")
    List<Diary> findRecentByCoupleOrderByCreatedAtDesc(@Param("couple") Couple couple, Pageable pageable);
    
    // Find diaries that need AI processing
    List<Diary> findByAiProcessedFalseOrderByCreatedAtAsc();
    
    // Count diaries by user
    long countByUser(User user);
    
    // Count diaries by couple
    long countByCouple(Couple couple);
    
    // ID-based methods for backward compatibility
    @Query("SELECT d FROM Diary d WHERE d.couple.id = :coupleId AND d.status = 'PUBLISHED' ORDER BY d.createdAt DESC")
    List<Diary> findRecentByCoupleIdOrderByCreatedAtDesc(@Param("coupleId") Long coupleId, Pageable pageable);
    long countByUserId(Long userId);
    long countByCoupleId(Long coupleId);
    
    // Find diaries by emotion
    @Query("SELECT d FROM Diary d WHERE d.couple = :couple AND d.status = 'PUBLISHED' AND d.aiEmotion = :emotion ORDER BY d.diaryDate DESC")
    List<Diary> findByCoupleAndEmotion(@Param("couple") Couple couple, @Param("emotion") String emotion);
    
    // Get diary statistics for a specific period
    @Query("SELECT d.aiEmotion, COUNT(d) FROM Diary d WHERE d.couple = :couple AND d.status = 'PUBLISHED' AND d.diaryDate BETWEEN :startDate AND :endDate AND d.aiEmotion IS NOT NULL GROUP BY d.aiEmotion")
    List<Object[]> getEmotionStatsByDateRange(@Param("couple") Couple couple, 
                                             @Param("startDate") LocalDate startDate, 
                                             @Param("endDate") LocalDate endDate);
    
    // ID-based methods for backward compatibility
    @Query("SELECT d FROM Diary d WHERE d.couple.id = :coupleId AND d.status = 'PUBLISHED' AND d.aiEmotion = :emotion ORDER BY d.diaryDate DESC")
    List<Diary> findByCoupleIdAndEmotion(@Param("coupleId") Long coupleId, @Param("emotion") String emotion);
    
    @Query("SELECT d.aiEmotion, COUNT(d) FROM Diary d WHERE d.couple.id = :coupleId AND d.status = 'PUBLISHED' AND d.diaryDate BETWEEN :startDate AND :endDate AND d.aiEmotion IS NOT NULL GROUP BY d.aiEmotion")
    List<Object[]> getEmotionStatsByDateRangeAndCoupleId(@Param("coupleId") Long coupleId, 
                                                        @Param("startDate") LocalDate startDate, 
                                                        @Param("endDate") LocalDate endDate);
}