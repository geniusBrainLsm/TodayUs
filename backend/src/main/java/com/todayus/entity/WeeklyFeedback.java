package com.todayus.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.time.LocalDate;

@Entity
@Table(name = "weekly_feedbacks")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WeeklyFeedback {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sender_id", nullable = false, foreignKey = @ForeignKey(value = ConstraintMode.NO_CONSTRAINT))
    private User sender;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "receiver_id", nullable = false, foreignKey = @ForeignKey(value = ConstraintMode.NO_CONSTRAINT))
    private User receiver;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "couple_id", nullable = false, foreignKey = @ForeignKey(value = ConstraintMode.NO_CONSTRAINT))
    private Couple couple;
    
    @Column(name = "week_of", nullable = false)
    private LocalDate weekOf; // 해당 주의 토요일 날짜
    
    @Column(name = "original_message", columnDefinition = "TEXT", nullable = false)
    private String originalMessage; // 원본 서운함 메시지
    
    @Column(name = "refined_message", columnDefinition = "TEXT")
    private String refinedMessage; // AI가 순화한 메시지
    
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private FeedbackStatus status = FeedbackStatus.PENDING;
    
    @Column(name = "is_read", nullable = false)
    private Boolean isRead = false;
    
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;
    
    @Column(name = "processed_at")
    private LocalDateTime processedAt; // AI 처리 완료 시각
    
    @Column(name = "delivered_at")
    private LocalDateTime deliveredAt; // 상대방에게 전달된 시각
    
    @Column(name = "read_at")
    private LocalDateTime readAt; // 상대방이 읽은 시각
    
    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }
    
    public enum FeedbackStatus {
        PENDING,    // 작성됨, AI 처리 대기 중
        PROCESSING, // AI 처리 중
        PROCESSED,  // AI 처리 완료, 전달 준비됨
        DELIVERED,  // 상대방에게 전달됨
        READ        // 상대방이 읽음
    }
    
    // 비즈니스 메소드
    public void markAsProcessed(String refinedMessage) {
        this.refinedMessage = refinedMessage;
        this.status = FeedbackStatus.PROCESSED;
        this.processedAt = LocalDateTime.now();
    }
    
    public void markAsDelivered() {
        this.status = FeedbackStatus.DELIVERED;
        this.deliveredAt = LocalDateTime.now();
    }
    
    public void markAsRead() {
        this.isRead = true;
        this.status = FeedbackStatus.READ;
        this.readAt = LocalDateTime.now();
    }
}