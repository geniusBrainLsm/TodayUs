package com.todayus.repository;

import com.todayus.entity.Couple;
import com.todayus.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface CoupleRepository extends JpaRepository<Couple, Long> {
    
    @Query("SELECT c FROM Couple c WHERE (c.user1 = :user OR c.user2 = :user) AND c.status = 'CONNECTED'")
    Optional<Couple> findByUserAndStatus(@Param("user") User user);
    
    @Query("SELECT c FROM Couple c WHERE c.user1 = :user OR c.user2 = :user")
    Optional<Couple> findByUser(@Param("user") User user);
    
    @Query("SELECT CASE WHEN COUNT(c) > 0 THEN TRUE ELSE FALSE END FROM Couple c " +
           "WHERE (c.user1 = :user OR c.user2 = :user) AND c.status = 'CONNECTED'")
    boolean existsByUserAndConnected(@Param("user") User user);
    
    @Query("SELECT c FROM Couple c WHERE " +
           "((c.user1 = :user1 AND c.user2 = :user2) OR " +
           " (c.user1 = :user2 AND c.user2 = :user1))")
    Optional<Couple> findByUsers(@Param("user1") User user1, @Param("user2") User user2);
    
    @Query("SELECT c FROM Couple c WHERE c.user1 = :user OR c.user2 = :user")
    Optional<Couple> findByUser1OrUser2(@Param("user") User user);
    
    // Keep ID-based methods for backward compatibility where needed
    @Query("SELECT c FROM Couple c WHERE (c.user1.id = :userId OR c.user2.id = :userId) AND c.status = 'CONNECTED'")
    Optional<Couple> findByUserIdAndStatus(@Param("userId") Long userId);
    
    @Query("SELECT c FROM Couple c WHERE c.user1.id = :userId OR c.user2.id = :userId")
    Optional<Couple> findByUserId(@Param("userId") Long userId);
    
    @Query("SELECT c FROM Couple c WHERE c.user1.id = :userId OR c.user2.id = :userId")
    Optional<Couple> findByUser1OrUser2ByUserId(@Param("userId") Long userId);
}