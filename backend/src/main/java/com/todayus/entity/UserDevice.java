package com.todayus.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Entity
@Table(name = "user_devices")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserDevice {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false)
    private Long userId;
    
    @Column(nullable = false, unique = true)
    private String fcmToken;
    
    @Column(nullable = false)
    private String deviceType; // android, ios, web
    
    @Column
    private String deviceInfo; // 기기 정보 (선택사항)
    
    @Column(nullable = false)
    private LocalDateTime registeredAt;
    
    @Column
    private LocalDateTime lastUsedAt;
    
    @Column(nullable = false)
    @Builder.Default
    private Boolean isActive = true;
    
    @PrePersist
    protected void onCreate() {
        registeredAt = LocalDateTime.now();
        lastUsedAt = LocalDateTime.now();
    }
    
    @PreUpdate
    protected void onUpdate() {
        lastUsedAt = LocalDateTime.now();
    }
}