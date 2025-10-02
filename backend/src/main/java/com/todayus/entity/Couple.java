package com.todayus.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;

@Entity
@Table(name = "couples")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EntityListeners(AuditingEntityListener.class)
public class Couple {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user1_id", nullable = false, foreignKey = @ForeignKey(value = ConstraintMode.NO_CONSTRAINT))
    private User user1;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user2_id", nullable = false, foreignKey = @ForeignKey(value = ConstraintMode.NO_CONSTRAINT))
    private User user2;
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private CoupleStatus status;
    
    @Column(nullable = false)
    private LocalDateTime connectedAt;
    
    @Column(name = "anniversary_date")
    private LocalDate anniversaryDate;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "anniversary_setter_id", foreignKey = @ForeignKey(value = ConstraintMode.NO_CONSTRAINT))
    private User anniversarySetter;
    
    @CreatedDate
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    @LastModifiedDate
    @Column(nullable = false)
    private LocalDateTime updatedAt;

    @Builder.Default
    @Column(nullable = false)
    private Integer oilBalance = 0;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "active_robot_id", foreignKey = @ForeignKey(value = ConstraintMode.NO_CONSTRAINT))
    private AiRobot activeRobot;

    public enum CoupleStatus {
        CONNECTED, DISCONNECTED
    }
    
    public User getPartner(User currentUser) {
        if (currentUser.equals(user1)) {
            return user2;
        } else if (currentUser.equals(user2)) {
            return user1;
        }
        throw new IllegalArgumentException("현재 사용자가 이 커플에 속하지 않습니다.");
    }
    
    public Long getPartnerId(Long currentUserId) {
        if (currentUserId.equals(user1.getId())) {
            return user2.getId();
        } else if (currentUserId.equals(user2.getId())) {
            return user1.getId();
        }
        throw new IllegalArgumentException("현재 사용자가 이 커플에 속하지 않습니다.");
    }
    
    public boolean contains(User user) {
        return user1.equals(user) || user2.equals(user);
    }
    
    public boolean contains(Long userId) {
        return user1.getId().equals(userId) || user2.getId().equals(userId);
    }
    
    public void updateAnniversaryDate(LocalDate anniversaryDate, User setter) {
        this.anniversaryDate = anniversaryDate;
        this.anniversarySetter = setter;
    }
    
    public boolean isAnniversarySetBy(User user) {
        return anniversarySetter != null && anniversarySetter.equals(user);
    }
    
    public boolean isAnniversarySetBy(Long userId) {
        return anniversarySetter != null && anniversarySetter.getId().equals(userId);
    }
    
    public boolean canSetAnniversary(User user) {
        return anniversarySetter == null || contains(user);
    }
    
    public boolean canSetAnniversary(Long userId) {
        return anniversarySetter == null || contains(userId);
    }
    
    public Long getDaysSinceAnniversary() {
        if (anniversaryDate == null) {
            return null;
        }
        return ChronoUnit.DAYS.between(anniversaryDate, LocalDate.now()) + 1;
    }
    
    public boolean hasAnniversaryDate() {
        return anniversaryDate != null;
    }

    // Oil management methods
    public Integer getOilBalance() {
        return this.oilBalance == null ? 0 : this.oilBalance;
    }

    public void addOil(int amount) {
        if (amount <= 0) {
            return;
        }
        this.oilBalance = Math.max(0, (this.oilBalance == null ? 0 : this.oilBalance) + amount);
    }

    public void spendOil(int amount) {
        if (amount <= 0) {
            return;
        }
        int current = this.oilBalance == null ? 0 : this.oilBalance;
        this.oilBalance = Math.max(0, current - amount);
    }

    public boolean hasEnoughOil(int amount) {
        return (this.oilBalance == null ? 0 : this.oilBalance) >= amount;
    }

    // Robot management methods
    public void activateRobot(AiRobot robot) {
        this.activeRobot = robot;
    }

    public AiRobot getActiveRobot() {
        return this.activeRobot;
    }
}