package com.todayus.controller;

import com.todayus.dto.TimeCapsuleDto;
import com.todayus.security.CustomOAuth2User;
import com.todayus.service.TimeCapsuleService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api/time-capsules")
@RequiredArgsConstructor
public class TimeCapsuleController {
    
    private final TimeCapsuleService timeCapsuleService;
    
    @PostMapping
    public ResponseEntity<TimeCapsuleDto.Response> createTimeCapsule(
            @AuthenticationPrincipal CustomOAuth2User user,
            @Valid @RequestBody TimeCapsuleDto.CreateRequest request) {
        
        log.info("Creating time capsule for user: {} with open date: {}", user.getEmail(), request.getOpenDate());
        
        try {
            TimeCapsuleDto.Response response = timeCapsuleService.createTimeCapsule(user.getEmail(), request);
            return ResponseEntity.ok(response);
            
        } catch (IllegalStateException e) {
            log.warn("Failed to create time capsule for user {}: {}", user.getEmail(), e.getMessage());
            return ResponseEntity.badRequest().build();
            
        } catch (Exception e) {
            log.error("Error creating time capsule for user {}: {}", user.getEmail(), e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }
    
    @GetMapping
    public ResponseEntity<Page<TimeCapsuleDto.ListResponse>> getTimeCapsules(
            @AuthenticationPrincipal CustomOAuth2User user,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        
        log.info("Getting time capsules for user: {} (page: {}, size: {})", user.getEmail(), page, size);
        
        try {
            Page<TimeCapsuleDto.ListResponse> response = timeCapsuleService.getTimeCapsules(user.getEmail(), page, size);
            return ResponseEntity.ok(response);
            
        } catch (IllegalStateException e) {
            log.warn("Failed to get time capsules for user {}: {}", user.getEmail(), e.getMessage());
            return ResponseEntity.badRequest().build();
            
        } catch (Exception e) {
            log.error("Error getting time capsules for user {}: {}", user.getEmail(), e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }
    
    @GetMapping("/{timeCapsuleId}")
    public ResponseEntity<TimeCapsuleDto.Response> getTimeCapsule(
            @AuthenticationPrincipal CustomOAuth2User user,
            @PathVariable Long timeCapsuleId) {
        
        log.info("Getting time capsule: {} for user: {}", timeCapsuleId, user.getEmail());
        
        try {
            TimeCapsuleDto.Response response = timeCapsuleService.getTimeCapsule(user.getEmail(), timeCapsuleId);
            return ResponseEntity.ok(response);
            
        } catch (IllegalStateException e) {
            log.warn("Failed to get time capsule {} for user {}: {}", timeCapsuleId, user.getEmail(), e.getMessage());
            return ResponseEntity.badRequest().build();
            
        } catch (Exception e) {
            log.error("Error getting time capsule {} for user {}: {}", timeCapsuleId, user.getEmail(), e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }
    
    @PostMapping("/{timeCapsuleId}/open")
    public ResponseEntity<TimeCapsuleDto.Response> openTimeCapsule(
            @AuthenticationPrincipal CustomOAuth2User user,
            @PathVariable Long timeCapsuleId) {
        
        log.info("Opening time capsule: {} by user: {}", timeCapsuleId, user.getEmail());
        
        try {
            TimeCapsuleDto.Response response = timeCapsuleService.openTimeCapsule(user.getEmail(), timeCapsuleId);
            return ResponseEntity.ok(response);
            
        } catch (IllegalStateException e) {
            log.warn("Failed to open time capsule {} for user {}: {}", timeCapsuleId, user.getEmail(), e.getMessage());
            return ResponseEntity.badRequest().build();
            
        } catch (Exception e) {
            log.error("Error opening time capsule {} for user {}: {}", timeCapsuleId, user.getEmail(), e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }
    
    @GetMapping("/openable")
    public ResponseEntity<List<TimeCapsuleDto.ListResponse>> getOpenableTimeCapsules(
            @AuthenticationPrincipal CustomOAuth2User user) {
        
        log.info("Getting openable time capsules for user: {}", user.getEmail());
        
        try {
            List<TimeCapsuleDto.ListResponse> response = timeCapsuleService.getOpenableTimeCapsules(user.getEmail());
            return ResponseEntity.ok(response);
            
        } catch (IllegalStateException e) {
            log.warn("Failed to get openable time capsules for user {}: {}", user.getEmail(), e.getMessage());
            return ResponseEntity.badRequest().build();
            
        } catch (Exception e) {
            log.error("Error getting openable time capsules for user {}: {}", user.getEmail(), e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }
    
    @GetMapping("/summary")
    public ResponseEntity<TimeCapsuleDto.Summary> getTimeCapsuleSummary(
            @AuthenticationPrincipal CustomOAuth2User user) {
        
        log.info("Getting time capsule summary for user: {}", user.getEmail());
        
        try {
            TimeCapsuleDto.Summary response = timeCapsuleService.getTimeCapsuleSummary(user.getEmail());
            return ResponseEntity.ok(response);
            
        } catch (IllegalStateException e) {
            log.warn("Failed to get time capsule summary for user {}: {}", user.getEmail(), e.getMessage());
            return ResponseEntity.badRequest().build();
            
        } catch (Exception e) {
            log.error("Error getting time capsule summary for user {}: {}", user.getEmail(), e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }
    
    @DeleteMapping("/{timeCapsuleId}")
    public ResponseEntity<Void> deleteTimeCapsule(
            @AuthenticationPrincipal CustomOAuth2User user,
            @PathVariable Long timeCapsuleId) {
        
        log.info("Deleting time capsule: {} by user: {}", timeCapsuleId, user.getEmail());
        
        try {
            timeCapsuleService.deleteTimeCapsule(user.getEmail(), timeCapsuleId);
            return ResponseEntity.noContent().build();
            
        } catch (IllegalStateException e) {
            log.warn("Failed to delete time capsule {} for user {}: {}", timeCapsuleId, user.getEmail(), e.getMessage());
            return ResponseEntity.badRequest().build();
            
        } catch (Exception e) {
            log.error("Error deleting time capsule {} for user {}: {}", timeCapsuleId, user.getEmail(), e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }
}