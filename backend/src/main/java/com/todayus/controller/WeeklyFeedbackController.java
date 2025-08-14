package com.todayus.controller;

import com.todayus.dto.WeeklyFeedbackDto;
import com.todayus.security.CustomOAuth2User;
import com.todayus.service.WeeklyFeedbackService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api/weekly-feedback")
@RequiredArgsConstructor
public class WeeklyFeedbackController {

    private final WeeklyFeedbackService weeklyFeedbackService;

    /**
     * 현재 시간이 피드백 작성 가능한 시간인지 확인
     */
    @GetMapping("/availability")
    public ResponseEntity<WeeklyFeedbackDto.WeeklyAvailabilityResponse> checkAvailability(
            @AuthenticationPrincipal CustomOAuth2User user) {
        
        log.info("Checking feedback availability for user: {}", user.getEmail());
        
        try {
            WeeklyFeedbackDto.WeeklyAvailabilityResponse response = 
                    weeklyFeedbackService.checkAvailability(user.getEmail());
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            log.error("Error checking feedback availability for user {}: {}", user.getEmail(), e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * 주간 피드백 작성
     */
    @PostMapping
    public ResponseEntity<WeeklyFeedbackDto.Response> createFeedback(
            @AuthenticationPrincipal CustomOAuth2User user,
            @Valid @RequestBody WeeklyFeedbackDto.CreateRequest request) {
        
        log.info("Creating weekly feedback for user: {}", user.getEmail());
        
        try {
            WeeklyFeedbackDto.Response response = weeklyFeedbackService.createFeedback(user.getEmail(), request);
            return ResponseEntity.ok(response);
            
        } catch (IllegalStateException e) {
            log.warn("Failed to create feedback for user {}: {}", user.getEmail(), e.getMessage());
            return ResponseEntity.badRequest().build();
            
        } catch (Exception e) {
            log.error("Error creating feedback for user {}: {}", user.getEmail(), e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * 받은 피드백 목록 조회 (읽지 않은 것만)
     */
    @GetMapping("/unread")
    public ResponseEntity<List<WeeklyFeedbackDto.ListResponse>> getUnreadFeedbacks(
            @AuthenticationPrincipal CustomOAuth2User user) {
        
        log.info("Getting unread feedbacks for user: {}", user.getEmail());
        
        try {
            List<WeeklyFeedbackDto.ListResponse> response = 
                    weeklyFeedbackService.getUnreadFeedbacks(user.getEmail());
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            log.error("Error getting unread feedbacks for user {}: {}", user.getEmail(), e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * 피드백 히스토리 조회 (페이지네이션)
     */
    @GetMapping("/history")
    public ResponseEntity<Page<WeeklyFeedbackDto.ListResponse>> getFeedbackHistory(
            @AuthenticationPrincipal CustomOAuth2User user,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        
        log.info("Getting feedback history for user: {} (page: {}, size: {})", user.getEmail(), page, size);
        
        try {
            Page<WeeklyFeedbackDto.ListResponse> response = 
                    weeklyFeedbackService.getFeedbackHistory(user.getEmail(), page, size);
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            log.error("Error getting feedback history for user {}: {}", user.getEmail(), e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * 특정 피드백 상세 조회
     */
    @GetMapping("/{feedbackId}")
    public ResponseEntity<WeeklyFeedbackDto.Response> getFeedback(
            @AuthenticationPrincipal CustomOAuth2User user,
            @PathVariable Long feedbackId) {
        
        log.info("Getting feedback: {} for user: {}", feedbackId, user.getEmail());
        
        try {
            WeeklyFeedbackDto.Response response = weeklyFeedbackService.getFeedback(user.getEmail(), feedbackId);
            return ResponseEntity.ok(response);
            
        } catch (IllegalArgumentException e) {
            log.warn("Feedback not found: {} for user: {}", feedbackId, user.getEmail());
            return ResponseEntity.notFound().build();
            
        } catch (IllegalStateException e) {
            log.warn("Unauthorized access to feedback: {} by user: {}", feedbackId, user.getEmail());
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
            
        } catch (Exception e) {
            log.error("Error getting feedback {} for user {}: {}", feedbackId, user.getEmail(), e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }
}