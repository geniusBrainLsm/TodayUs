package com.todayus.repository;

import com.todayus.entity.InviteCode;
import com.todayus.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface InviteCodeRepository extends JpaRepository<InviteCode, Long> {
    
    // Entity-based methods
    Optional<InviteCode> findByCodeAndStatus(String code, InviteCode.InviteStatus status);
    
    @Query("SELECT ic FROM InviteCode ic WHERE ic.inviter = :inviter AND ic.status = 'ACTIVE' ORDER BY ic.createdAt DESC LIMIT 1")
    Optional<InviteCode> findActiveInviteByInviter(@Param("inviter") User inviter);
    
    @Modifying
    @Transactional
    @Query("UPDATE InviteCode ic SET ic.status = 'EXPIRED' WHERE ic.inviter = :inviter AND ic.status = 'ACTIVE'")
    int expireActiveInvitesByInviter(@Param("inviter") User inviter);
    
    // ID-based methods for backward compatibility
    @Query("SELECT ic FROM InviteCode ic WHERE ic.inviter.id = :inviterId AND ic.status = 'ACTIVE' ORDER BY ic.createdAt DESC LIMIT 1")
    Optional<InviteCode> findActiveInviteByInviterId(@Param("inviterId") Long inviterId);
    
    @Modifying
    @Transactional
    @Query("UPDATE InviteCode ic SET ic.status = 'EXPIRED' WHERE ic.inviter.id = :inviterId AND ic.status = 'ACTIVE'")
    int expireActiveInvitesByInviterId(@Param("inviterId") Long inviterId);
    
    // Common methods
    @Query("SELECT ic FROM InviteCode ic WHERE ic.expiresAt < :now AND ic.status = 'ACTIVE'")
    List<InviteCode> findExpiredActiveCodes(@Param("now") LocalDateTime now);
    
    @Modifying
    @Transactional
    @Query("UPDATE InviteCode ic SET ic.status = 'EXPIRED' WHERE ic.expiresAt < :now AND ic.status = 'ACTIVE'")
    int expireOldCodes(@Param("now") LocalDateTime now);
    
    boolean existsByCode(String code);
    
    // 특정 사용자의 모든 활성 초대 코드 조회 (중복 정리용)
    @Query("SELECT ic FROM InviteCode ic WHERE ic.inviter = :inviter AND ic.status = 'ACTIVE' ORDER BY ic.createdAt DESC")
    List<InviteCode> findAllActiveInvitesByInviter(@Param("inviter") User inviter);
}