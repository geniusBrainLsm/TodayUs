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
@Table(name = "invite_codes", 
       indexes = {
           @Index(name = "idx_invite_code", columnList = "code"),
           @Index(name = "idx_invite_expires_at", columnList = "expiresAt")
       })
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EntityListeners(AuditingEntityListener.class)
public class InviteCode {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false, unique = true, length = 6)
    private String code;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "inviter_id", nullable = false, foreignKey = @ForeignKey(value = ConstraintMode.NO_CONSTRAINT))
    private User inviter;
    
    @Column(nullable = false)
    private LocalDateTime expiresAt;
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private InviteStatus status;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "invitee_id", foreignKey = @ForeignKey(value = ConstraintMode.NO_CONSTRAINT))
    private User invitee;
    
    @Column
    private LocalDateTime usedAt;
    
    @CreatedDate
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    public enum InviteStatus {
        ACTIVE, USED, EXPIRED
    }
    
    public boolean isExpired() {
        return expiresAt != null && LocalDateTime.now().isAfter(expiresAt);
    }
    
    public boolean isUsable() {
        return status == InviteStatus.ACTIVE && !isExpired();
    }
    
    public void markAsUsed(User invitee) {
        this.status = InviteStatus.USED;
        this.invitee = invitee;
        this.usedAt = LocalDateTime.now();
    }
    
    public void markAsExpired() {
        this.status = InviteStatus.EXPIRED;
    }
}