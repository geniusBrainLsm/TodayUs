package com.todayus.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Entity
@Table(name = "couple_messages")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EntityListeners(AuditingEntityListener.class)
public class CoupleMessage {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "couple_id", nullable = false, foreignKey = @ForeignKey(value = ConstraintMode.NO_CONSTRAINT))
    private Couple couple;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sender_id", nullable = false, foreignKey = @ForeignKey(value = ConstraintMode.NO_CONSTRAINT))
    private User sender;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "receiver_id", nullable = false, foreignKey = @ForeignKey(value = ConstraintMode.NO_CONSTRAINT))
    private User receiver;
    
    @Column(name = "original_message", nullable = false, columnDefinition = "TEXT")
    private String originalMessage;
    
    @Column(name = "ai_processed_message", nullable = false, columnDefinition = "TEXT")
    private String aiProcessedMessage;
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private MessageStatus status;
    
    @Column(name = "delivered_at")
    private LocalDateTime deliveredAt;
    
    @Column(name = "read_at")
    private LocalDateTime readAt;
    
    @CreatedDate
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    public enum MessageStatus {
        PENDING,    // AI 처리 대기중
        READY,      // 전달 준비 완료
        DELIVERED,  // 상대방에게 전달됨 (팝업 표시됨)
        READ        // 상대방이 읽음
    }
    
    public void markAsDelivered() {
        this.status = MessageStatus.DELIVERED;
        this.deliveredAt = LocalDateTime.now();
    }
    
    public void markAsRead() {
        this.status = MessageStatus.READ;
        this.readAt = LocalDateTime.now();
    }
    
    public boolean isReadyToDeliver() {
        return this.status == MessageStatus.READY;
    }
    
    public boolean isDelivered() {
        return this.status == MessageStatus.DELIVERED || this.status == MessageStatus.READ;
    }
}