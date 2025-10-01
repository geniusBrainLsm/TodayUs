package com.todayus.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Entity
@Table(name = "boards")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EntityListeners(AuditingEntityListener.class)
public class Board {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, foreignKey = @ForeignKey(value = ConstraintMode.NO_CONSTRAINT))
    private User author;

    @Column(nullable = false)
    private String title;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String content;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private BoardType type;

    @Column(nullable = false)
    @Builder.Default
    private Boolean pinned = false;

    @Column(nullable = false)
    @Builder.Default
    private Integer viewCount = 0;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private BoardStatus status = BoardStatus.ACTIVE;

    @CreatedDate
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(nullable = false)
    private LocalDateTime updatedAt;

    public enum BoardType {
        NOTICE,        // 공지사항 (관리자만 작성 가능)
        SUGGESTION,    // 건의사항 (일반 사용자 작성)
        FAQ            // 자주 묻는 질문 (관리자만 작성 가능)
    }

    public enum BoardStatus {
        ACTIVE,        // 활성
        ARCHIVED,      // 보관됨
        DELETED        // 삭제됨
    }

    public void incrementViewCount() {
        this.viewCount++;
    }

    public void pin() {
        this.pinned = true;
    }

    public void unpin() {
        this.pinned = false;
    }

    public void archive() {
        this.status = BoardStatus.ARCHIVED;
    }

    public void delete() {
        this.status = BoardStatus.DELETED;
    }

    public void activate() {
        this.status = BoardStatus.ACTIVE;
    }

    public boolean isOwnedBy(User user) {
        return this.author.equals(user);
    }

    public boolean isOwnedBy(Long userId) {
        return this.author.getId().equals(userId);
    }

    public boolean canEdit(User user) {
        // 관리자이거나 본인이 작성한 글인 경우
        return user.getRole() == User.Role.ADMIN || isOwnedBy(user);
    }

    public boolean canDelete(User user) {
        // 관리자이거나 본인이 작성한 글인 경우
        return user.getRole() == User.Role.ADMIN || isOwnedBy(user);
    }
}
