package com.todayus.repository;

import com.todayus.entity.Couple;
import com.todayus.entity.CoupleMessage;
import com.todayus.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface CoupleMessageRepository extends JpaRepository<CoupleMessage, Long> {
    
    // 특정 사용자가 받을 준비된 메시지 조회 (팝업 표시용)
    @Query("SELECT cm FROM CoupleMessage cm WHERE cm.receiver = :receiver AND cm.status = 'READY' ORDER BY cm.createdAt ASC")
    Optional<CoupleMessage> findReadyMessageForReceiver(@Param("receiver") User receiver);
    
    // 특정 기간 내 보낸 메시지 개수 (주간 제한 확인용)
    @Query("SELECT COUNT(cm) FROM CoupleMessage cm WHERE cm.sender = :sender AND cm.createdAt >= :startDate")
    long countBySenderAndCreatedAtAfter(@Param("sender") User sender, @Param("startDate") LocalDateTime startDate);
    
    // 커플의 모든 메시지 조회 (최신 순)
    @Query("SELECT cm FROM CoupleMessage cm WHERE cm.couple = :couple ORDER BY cm.createdAt DESC")
    List<CoupleMessage> findByCoupleOrderByCreatedAtDesc(@Param("couple") Couple couple);
    
    // 특정 사용자가 받은 메시지들 조회
    @Query("SELECT cm FROM CoupleMessage cm WHERE cm.receiver = :receiver ORDER BY cm.createdAt DESC")
    List<CoupleMessage> findByReceiverOrderByCreatedAtDesc(@Param("receiver") User receiver);
    
    // 특정 사용자가 보낸 메시지들 조회
    @Query("SELECT cm FROM CoupleMessage cm WHERE cm.sender = :sender ORDER BY cm.createdAt DESC")
    List<CoupleMessage> findBySenderOrderByCreatedAtDesc(@Param("sender") User sender);
    
    // ID-based methods for backward compatibility
    @Query("SELECT cm FROM CoupleMessage cm WHERE cm.receiver.id = :receiverId AND cm.status = 'READY' ORDER BY cm.createdAt ASC")
    Optional<CoupleMessage> findReadyMessageForReceiverId(@Param("receiverId") Long receiverId);
    
    @Query("SELECT COUNT(cm) FROM CoupleMessage cm WHERE cm.sender.id = :senderId AND cm.createdAt >= :startDate")
    long countBySenderIdAndCreatedAtAfter(@Param("senderId") Long senderId, @Param("startDate") LocalDateTime startDate);
    
    @Query("SELECT cm FROM CoupleMessage cm WHERE cm.couple.id = :coupleId ORDER BY cm.createdAt DESC")
    List<CoupleMessage> findByCoupleIdOrderByCreatedAtDesc(@Param("coupleId") Long coupleId);
    
    // AI 처리 대기중인 메시지들 조회
    @Query("SELECT cm FROM CoupleMessage cm WHERE cm.status = 'PENDING' ORDER BY cm.createdAt ASC")
    List<CoupleMessage> findPendingMessages();

    // 특정 사용자가 보낸 가장 최근 메시지 조회 (쿨다운 계산용)
    Optional<CoupleMessage> findTopBySenderOrderByCreatedAtDesc(User sender);
}