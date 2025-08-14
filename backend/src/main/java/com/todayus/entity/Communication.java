package com.todayus.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Entity
@Table(name = "communications")
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EntityListeners(AuditingEntityListener.class)
public class Communication {
    
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
    
    @Column(nullable = false, length = 500)
    private String title;
    
    @Column(nullable = false, columnDefinition = "TEXT")
    private String content;
    
    @Column(name = "ai_suggestion", columnDefinition = "TEXT")
    private String aiSuggestion;
    
    @Column(name = "ai_processed", nullable = false)
    private Boolean aiProcessed = false;
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private CommunicationType type;
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private CommunicationStatus status;
    
    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    @Column(name = "responded_at")
    private LocalDateTime respondedAt;
    
    public enum CommunicationType {
        CONCERN,        // 고민 상담
        CONFLICT,       // 갈등 해결
        APPRECIATION,   // 감사 표현
        APOLOGY,       // 사과
        SUGGESTION     // 제안
    }
    
    public enum CommunicationStatus {
        PENDING,        // 대기 중
        AI_REVIEWED,    // AI 검토 완료
        DELIVERED,      // 전달됨
        RESPONDED       // 응답 완료
    }
    
    // AI 제안 추가
    public void addAiSuggestion(String suggestion) {
        this.aiSuggestion = suggestion;
        this.aiProcessed = true;
        if (this.status == CommunicationStatus.PENDING) {
            this.status = CommunicationStatus.AI_REVIEWED;
        }
    }
    
    // 상태 업데이트
    public void updateStatus(CommunicationStatus newStatus) {
        this.status = newStatus;
        if (newStatus == CommunicationStatus.RESPONDED) {
            this.respondedAt = LocalDateTime.now();
        }
    }
}