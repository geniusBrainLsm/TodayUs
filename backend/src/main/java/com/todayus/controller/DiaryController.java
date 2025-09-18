package com.todayus.controller;

import com.todayus.dto.DiaryDto;
import com.todayus.security.CustomOAuth2User;
import com.todayus.service.DiaryService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/diaries")
@RequiredArgsConstructor
public class DiaryController {
    
    private final DiaryService diaryService;
    
    @PostMapping
    public ResponseEntity<DiaryDto.Response> createDiary(
            @AuthenticationPrincipal CustomOAuth2User user,
            @Valid @RequestBody DiaryDto.CreateRequest request) {
        
        // 인증된 사용자 확인
        if (user == null) {
            log.warn("Unauthenticated request to create diary - user parameter is null");
            return ResponseEntity.status(401).build(); // Unauthorized
        }
        
        log.info("Authenticated user type: {}", user.getClass().getName());
        log.info("User email: {}", user.getEmail());
        
        log.info("Creating diary for user: {} with date: {}", user.getEmail(), request.getDiaryDate());
        
        try {
            DiaryDto.Response response = diaryService.createDiary(user.getEmail(), request);
            return ResponseEntity.ok(response);
            
        } catch (IllegalStateException e) {
            log.warn("Failed to create diary for user {}: {}", user.getEmail(), e.getMessage());
            return ResponseEntity.badRequest().build();
            
        } catch (Exception e) {
            log.error("Error creating diary for user {}: {}", user.getEmail(), e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }
    
    @GetMapping
    public ResponseEntity<Page<DiaryDto.ListResponse>> getDiaries(
            @AuthenticationPrincipal CustomOAuth2User user,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        
        log.info("Getting diaries for user: {} (page: {}, size: {})", user.getEmail(), page, size);
        
        try {
            Page<DiaryDto.ListResponse> response = diaryService.getDiaries(user.getEmail(), page, size);
            return ResponseEntity.ok(response);
            
        } catch (IllegalStateException e) {
            log.warn("Failed to get diaries for user {}: {}", user.getEmail(), e.getMessage());
            return ResponseEntity.badRequest().build();
            
        } catch (Exception e) {
            log.error("Error getting diaries for user {}: {}", user.getEmail(), e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }
    
    @GetMapping("/{diaryId}")
    public ResponseEntity<DiaryDto.Response> getDiary(
            @AuthenticationPrincipal CustomOAuth2User user,
            @PathVariable Long diaryId) {
        
        log.info("Getting diary: {} for user: {}", diaryId, user.getEmail());
        
        try {
            DiaryDto.Response response = diaryService.getDiary(user.getEmail(), diaryId);
            return ResponseEntity.ok(response);
            
        } catch (IllegalStateException e) {
            log.warn("Failed to get diary {} for user {}: {}", diaryId, user.getEmail(), e.getMessage());
            return ResponseEntity.badRequest().build();
            
        } catch (Exception e) {
            log.error("Error getting diary {} for user {}: {}", diaryId, user.getEmail(), e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }
    
    @PutMapping("/{diaryId}")
    public ResponseEntity<DiaryDto.Response> updateDiary(
            @AuthenticationPrincipal CustomOAuth2User user,
            @PathVariable Long diaryId,
            @Valid @RequestBody DiaryDto.UpdateRequest request) {
        
        log.info("Updating diary: {} for user: {}", diaryId, user.getEmail());
        
        try {
            DiaryDto.Response response = diaryService.updateDiary(user.getEmail(), diaryId, request);
            return ResponseEntity.ok(response);
            
        } catch (IllegalStateException e) {
            log.warn("Failed to update diary {} for user {}: {}", diaryId, user.getEmail(), e.getMessage());
            return ResponseEntity.badRequest().build();
            
        } catch (Exception e) {
            log.error("Error updating diary {} for user {}: {}", diaryId, user.getEmail(), e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }
    
    @DeleteMapping("/{diaryId}")
    public ResponseEntity<Void> deleteDiary(
            @AuthenticationPrincipal CustomOAuth2User user,
            @PathVariable Long diaryId) {
        
        log.info("Deleting diary: {} for user: {}", diaryId, user.getEmail());
        
        try {
            diaryService.deleteDiary(user.getEmail(), diaryId);
            return ResponseEntity.noContent().build();
            
        } catch (IllegalStateException e) {
            log.warn("Failed to delete diary {} for user {}: {}", diaryId, user.getEmail(), e.getMessage());
            return ResponseEntity.badRequest().build();
            
        } catch (Exception e) {
            log.error("Error deleting diary {} for user {}: {}", diaryId, user.getEmail(), e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }
    
    @PostMapping("/{diaryId}/comments")
    public ResponseEntity<DiaryDto.CommentResponse> addComment(
            @AuthenticationPrincipal CustomOAuth2User user,
            @PathVariable Long diaryId,
            @Valid @RequestBody DiaryDto.CommentRequest request) {
        
        log.info("=== DiaryController: Adding comment ===");
        log.info("Diary ID: {}", diaryId);
        log.info("User: {}", user != null ? user.getEmail() : "null");
        log.info("Request: {}", request != null ? request.getContent() : "null request");
        
        if (user == null) {
            log.error("User is null - authentication failed");
            return ResponseEntity.status(401).build();
        }
        
        if (request == null) {
            log.error("Request is null");
            return ResponseEntity.badRequest().build();
        }
        
        try {
            DiaryDto.CommentResponse response = diaryService.addComment(user.getEmail(), diaryId, request);
            log.info("Comment added successfully. Response: {}", response);
            return ResponseEntity.ok(response);
            
        } catch (IllegalArgumentException e) {
            log.warn("Invalid argument for adding comment to diary {} for user {}: {}", diaryId, user.getEmail(), e.getMessage());
            return ResponseEntity.badRequest().build();
            
        } catch (IllegalStateException e) {
            log.warn("Failed to add comment to diary {} for user {}: {}", diaryId, user.getEmail(), e.getMessage());
            return ResponseEntity.badRequest().build();
            
        } catch (Exception e) {
            log.error("Error adding comment to diary {} for user {}: {}", diaryId, user.getEmail(), e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }
    
    @GetMapping("/recent")
    public ResponseEntity<List<DiaryDto.Response>> getRecentDiaries(
            @AuthenticationPrincipal CustomOAuth2User user,
            @RequestParam(defaultValue = "5") int limit) {
        
        log.info("Getting recent diaries for user: {} (limit: {})", user.getEmail(), limit);
        
        try {
            List<DiaryDto.Response> response = diaryService.getRecentDiaries(user.getEmail(), limit);
            return ResponseEntity.ok(response);
            
        } catch (IllegalStateException e) {
            log.warn("Failed to get recent diaries for user {}: {}", user.getEmail(), e.getMessage());
            return ResponseEntity.badRequest().build();
            
        } catch (Exception e) {
            log.error("Error getting recent diaries for user {}: {}", user.getEmail(), e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }
    
    @GetMapping("/emotions/stats")
    public ResponseEntity<List<DiaryDto.EmotionStats>> getEmotionStats(
            @AuthenticationPrincipal CustomOAuth2User user,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        
        log.info("Getting emotion stats for user: {} (period: {} to {})", user.getEmail(), startDate, endDate);
        
        try {
            List<DiaryDto.EmotionStats> response = diaryService.getEmotionStats(user.getEmail(), startDate, endDate);
            return ResponseEntity.ok(response);
            
        } catch (IllegalStateException e) {
            log.warn("Failed to get emotion stats for user {}: {}", user.getEmail(), e.getMessage());
            return ResponseEntity.badRequest().build();
            
        } catch (Exception e) {
            log.error("Error getting emotion stats for user {}: {}", user.getEmail(), e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }
    
    @PostMapping("/{diaryId}/ai-process")
    public ResponseEntity<Void> processAiAnalysis(
            @AuthenticationPrincipal CustomOAuth2User user,
            @PathVariable Long diaryId) {
        
        log.info("Processing AI analysis for diary: {} by user: {}", diaryId, user.getEmail());
        
        try {
            diaryService.processAiAnalysis(diaryId);
            return ResponseEntity.accepted().build();
            
        } catch (Exception e) {
            log.error("Error processing AI analysis for diary {} by user {}: {}", diaryId, user.getEmail(), e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }
    
    @GetMapping("/weekly-emotion-summary")
    public ResponseEntity<String> getWeeklyEmotionSummary(
            @AuthenticationPrincipal CustomOAuth2User user) {
        
        log.info("Getting weekly emotion summary for user: {}", user.getEmail());
        
        try {
            String summary = diaryService.generateWeeklyEmotionSummary(user.getEmail());
            return ResponseEntity.ok(summary);
            
        } catch (Exception e) {
            log.error("Error getting weekly emotion summary for user {}: {}", user.getEmail(), e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }
    
    @GetMapping("/couple-summary")
    public ResponseEntity<Map<String, Object>> getCoupleSummary(
            @AuthenticationPrincipal CustomOAuth2User user) {
        
        log.info("Getting couple summary for user: {}", user.getEmail());
        
        try {
            Map<String, Object> summary = diaryService.getCoupleSummary(user.getEmail());
            return ResponseEntity.ok(summary);
            
        } catch (Exception e) {
            log.error("Error getting couple summary for user {}: {}", user.getEmail(), e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }

    @GetMapping("/today/exists")
    public ResponseEntity<Map<String, Boolean>> checkTodayDiaryExists(
            @AuthenticationPrincipal CustomOAuth2User user) {

        log.info("Checking today's diary existence for user: {}", user.getEmail());

        try {
            boolean exists = diaryService.hasTodayDiary(user.getEmail());
            Map<String, Boolean> response = new HashMap<>();
            response.put("exists", exists);
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("Error checking today's diary for user {}: {}", user.getEmail(), e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }
}