package com.todayus.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
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
@Table(name = "ai_robots")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EntityListeners(AuditingEntityListener.class)
public class AiRobot {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 50)
    private String code;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(length = 255)
    private String tagline;

    @Column(length = 500)
    private String description;

    @Builder.Default
    @Column(nullable = false)
    private Integer priceOil = 0;

    @Column(length = 255)
    private String imageUrl;

    @Column(length = 255)
    private String splashImageUrl;

    @Column(length = 12)
    private String themeColorHex;

    @Column(length = 255)
    private String previewMessage;

    @Column(columnDefinition = "TEXT")
    private String chatSystemPrompt;

    @Column(columnDefinition = "TEXT")
    private String chatUserGuidance;

    @Column(columnDefinition = "TEXT")
    private String commentSystemPrompt;

    @Column(columnDefinition = "TEXT")
    private String commentUserGuidance;

    @Column(columnDefinition = "TEXT")
    private String emotionSystemPrompt;

    @Column
    private Integer chatMaxTokens;

    @Column
    private Integer commentMaxTokens;

    @Column
    private Integer emotionMaxTokens;

    @Column
    private Double chatTemperature;

    @Column
    private Double commentTemperature;

    @Column
    private Double emotionTemperature;

    @Builder.Default
    @Column(nullable = false)
    private Boolean defaultRobot = Boolean.FALSE;

    @Builder.Default
    @Column(nullable = false)
    private Boolean active = Boolean.TRUE;

    @Builder.Default
    @Column(nullable = false)
    private Integer displayOrder = 0;

    @CreatedDate
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(nullable = false)
    private LocalDateTime updatedAt;

    public boolean isDefaultRobot() {
        return Boolean.TRUE.equals(defaultRobot);
    }

    public boolean isActive() {
        return Boolean.TRUE.equals(active);
    }
}
