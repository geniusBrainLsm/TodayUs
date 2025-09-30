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

@Entity
@Table(name = "diaries")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EntityListeners(AuditingEntityListener.class)
public class Diary {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, foreignKey = @ForeignKey(value = ConstraintMode.NO_CONSTRAINT))
    private User user;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "couple_id", nullable = false, foreignKey = @ForeignKey(value = ConstraintMode.NO_CONSTRAINT))
    private Couple couple;
    
    @Column(nullable = false)
    private String title;
    
    @Column(nullable = false, columnDefinition = "TEXT")
    private String content;
    
    @Column(name = "diary_date", nullable = false)
    private LocalDate diaryDate;
    

    
    @Column(name = "ai_emotion")
    private String aiEmotion;
    
    @Column(name = "ai_comment", columnDefinition = "TEXT")
    private String aiComment;
    
    @Column(name = "ai_processed")
    private Boolean aiProcessed = false;
    
    @Column(name = "image_url")
    private String imageUrl;
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private DiaryStatus status;
    
    @CreatedDate
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    @LastModifiedDate
    @Column(nullable = false)
    private LocalDateTime updatedAt;
    
    public enum DiaryStatus {
        DRAFT, PUBLISHED, ARCHIVED
    }
    
    public void updateContent(String title, String content) {
        this.title = title;
        this.content = content;
    }
    
    public void updateContentWithImage(String title, String content, String imageUrl) {
        this.title = title;
        this.content = content;
        this.imageUrl = imageUrl;
    }
    
    public void updateAiAnalysis(String aiEmotion, String aiComment) {
        this.aiEmotion = aiEmotion;
        this.aiComment = aiComment;
        this.aiProcessed = true;
    }
    
    public void publish() {
        this.status = DiaryStatus.PUBLISHED;
    }
    
    public void archive() {
        this.status = DiaryStatus.ARCHIVED;
    }
    
    public boolean isOwnedBy(User user) {
        return this.user.equals(user);
    }
    
    public boolean isOwnedBy(Long userId) {
        return this.user.getId().equals(userId);
    }
    
    public boolean isAccessibleBy(User user, Couple couple) {
        // User can access their own diary or if they're in the same couple
        if (isOwnedBy(user)) {
            return true;
        }
        
        // Check if both this diary's couple and the provided couple are not null
        if (this.couple == null || couple == null) {
            return false;
        }
        
        // Check if they're in the same couple
        return this.couple.getId().equals(couple.getId());
    }
    
    public boolean isAccessibleBy(Long userId, Long coupleId) {
        // User can access their own diary or if they're in the same couple
        return isOwnedBy(userId) || this.couple.getId().equals(coupleId);
    }
}