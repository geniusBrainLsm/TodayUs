package com.todayus.repository;

import com.todayus.entity.Couple;
import com.todayus.entity.TimeCapsule;
import com.todayus.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface TimeCapsuleRepository extends JpaRepository<TimeCapsule, Long> {
    
    // Find time capsules by couple
    Page<TimeCapsule> findByCoupleOrderByCreatedAtDesc(Couple couple, Pageable pageable);
    
    // Find time capsules by author
    Page<TimeCapsule> findByAuthorOrderByCreatedAtDesc(User author, Pageable pageable);
    
    // Find time capsules that can be opened
    @Query("SELECT tc FROM TimeCapsule tc WHERE tc.couple = :couple AND tc.isOpened = false AND tc.openDate <= :today ORDER BY tc.openDate ASC")
    List<TimeCapsule> findOpenableTimeCapsules(@Param("couple") Couple couple, @Param("today") LocalDate today);
    
    // Find opened time capsules by couple
    @Query("SELECT tc FROM TimeCapsule tc WHERE tc.couple = :couple AND tc.isOpened = true ORDER BY tc.openedAt DESC")
    List<TimeCapsule> findOpenedTimeCapsules(@Param("couple") Couple couple, Pageable pageable);
    
    // Find unopened time capsules by couple
    @Query("SELECT tc FROM TimeCapsule tc WHERE tc.couple = :couple AND tc.isOpened = false ORDER BY tc.openDate ASC")
    List<TimeCapsule> findUnopenedTimeCapsules(@Param("couple") Couple couple, Pageable pageable);
    
    // Count unopened time capsules by couple
    long countByCoupleAndIsOpenedFalse(Couple couple);
    
    // Count opened time capsules by couple
    long countByCoupleAndIsOpenedTrue(Couple couple);
    
    // Count all time capsules by couple
    long countByCouple(Couple couple);
    
    // ID-based methods for backward compatibility
    Page<TimeCapsule> findByCoupleIdOrderByCreatedAtDesc(Long coupleId, Pageable pageable);
    Page<TimeCapsule> findByAuthorIdOrderByCreatedAtDesc(Long authorId, Pageable pageable);
    
    @Query("SELECT tc FROM TimeCapsule tc WHERE tc.couple.id = :coupleId AND tc.isOpened = false AND tc.openDate <= :today ORDER BY tc.openDate ASC")
    List<TimeCapsule> findOpenableTimeCapsulesByCoupleId(@Param("coupleId") Long coupleId, @Param("today") LocalDate today);
    
    long countByCoupleIdAndIsOpenedFalse(Long coupleId);
    long countByCoupleIdAndIsOpenedTrue(Long coupleId);
    long countByCoupleId(Long coupleId);
}