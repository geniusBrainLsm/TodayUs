package com.todayus.repository;

import com.todayus.entity.UserDevice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface UserDeviceRepository extends JpaRepository<UserDevice, Long> {
    
    /**
     * 사용자의 모든 활성 기기 조회
     */
    List<UserDevice> findByUserIdAndIsActiveTrue(Long userId);
    
    /**
     * FCM 토큰으로 기기 조회
     */
    Optional<UserDevice> findByFcmToken(String fcmToken);
    
    /**
     * 사용자와 기기 타입으로 조회
     */
    Optional<UserDevice> findByUserIdAndDeviceType(Long userId, String deviceType);
    
    /**
     * 모든 활성 기기 조회 (전체 발송용)
     */
    @Query("SELECT ud FROM UserDevice ud WHERE ud.isActive = true")
    List<UserDevice> findAllActiveDevices();
    
    /**
     * 특정 시간 이후 사용되지 않은 기기들 조회 (정리용)
     */
    @Query("SELECT ud FROM UserDevice ud WHERE ud.lastUsedAt < :cutoffDate")
    List<UserDevice> findInactiveDevices(@Param("cutoffDate") LocalDateTime cutoffDate);
    
    /**
     * 커플 상대방의 활성 기기들 조회
     */
    @Query("SELECT ud FROM UserDevice ud " +
           "WHERE ud.userId IN (" +
           "  SELECT CASE " +
           "    WHEN c.user1.id = :userId THEN c.user2.id " +
           "    WHEN c.user2.id = :userId THEN c.user1.id " +
           "  END " +
           "  FROM Couple c " +
           "  WHERE (c.user1.id = :userId OR c.user2.id = :userId) " +
           "  AND c.status = 'CONNECTED'" +
           ") AND ud.isActive = true")
    List<UserDevice> findPartnerDevices(@Param("userId") Long userId);
}