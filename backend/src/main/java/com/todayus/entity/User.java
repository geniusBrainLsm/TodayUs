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

import java.time.LocalDateTime;

@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EntityListeners(AuditingEntityListener.class)
public class User {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false, unique = true)
    private String email;
    
    @Column(nullable = false)
    private String name;
    
    @Column(unique = true)
    private String nickname;
    
    @Column
    private Boolean nicknameSet = false;
    
    @Column
    private String profileImageUrl;
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Provider provider;
    
    @Column(nullable = false)
    private String providerId;
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Role role;
    @Builder.Default
    @Column(nullable = false)
    private Integer oilBalance = 0;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "active_robot_id")
    private AiRobot activeRobot;

    
    @CreatedDate
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    @LastModifiedDate
    @Column(nullable = false)
    private LocalDateTime updatedAt;
    
    public enum Provider {
        GOOGLE, KAKAO
    }
    
    public enum Role {
        USER, ADMIN
    }
    
    public User updateProfile(String name, String profileImageUrl) {
        this.name = name;
        this.profileImageUrl = profileImageUrl;
        return this;
    }
    
    public User updateNickname(String nickname) {
        this.nickname = nickname;
        this.nicknameSet = true;
        return this;
    }
    
    public void setProfileImageUrl(String profileImageUrl) {
        this.profileImageUrl = profileImageUrl;
    }
    
    public String getProfileImageUrl() {
        return this.profileImageUrl;
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

    public void activateRobot(AiRobot robot) {
        this.activeRobot = robot;
    }
}
