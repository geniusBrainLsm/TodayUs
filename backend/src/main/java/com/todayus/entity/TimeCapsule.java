package com.todayus.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "time_capsules")
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EntityListeners(AuditingEntityListener.class)
public class TimeCapsule {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "couple_id", nullable = false, foreignKey = @ForeignKey(value = ConstraintMode.NO_CONSTRAINT))
    private Couple couple;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "author_id", nullable = false, foreignKey = @ForeignKey(value = ConstraintMode.NO_CONSTRAINT))
    private User author;
    
    @Column(nullable = false, length = 200)
    private String title;
    
    @Column(nullable = false, columnDefinition = "TEXT")
    private String content;
    
    @Column(name = "open_date", nullable = false)
    private LocalDate openDate;
    
    @Column(name = "is_opened", nullable = false)
    private Boolean isOpened = false;
    
    @Column(name = "opened_at")
    private LocalDateTime openedAt;
    
    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TimeCapsuleType type;
    
    public enum TimeCapsuleType {
        PERSONAL,    // 개인 타임캡슐
        COUPLE      // 커플 타임캡슐
    }
    
    // 타임캡슐 열기
    public void open() {
        this.isOpened = true;
        this.openedAt = LocalDateTime.now();
    }
    
    // 오픈 가능한지 확인
    public boolean canOpen() {
        return !isOpened && LocalDate.now().isAfter(openDate.minusDays(1));
    }
}