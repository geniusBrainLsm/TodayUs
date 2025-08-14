package com.todayus.controller;

import com.todayus.dto.AnniversaryDto;
import com.todayus.security.CustomOAuth2User;
import com.todayus.service.AnniversaryService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;

@Slf4j
@RestController
@RequestMapping("/api/anniversary")
@RequiredArgsConstructor
public class AnniversaryController {
    
    private final AnniversaryService anniversaryService;
    
    @PostMapping
    public ResponseEntity<AnniversaryDto.Response> setAnniversary(
            @AuthenticationPrincipal CustomOAuth2User user,
            @Valid @RequestBody AnniversaryDto.Request request) {
        
        log.info("Setting anniversary for user: {} with date: {}", 
                user.getEmail(), request.getAnniversaryDate());
        
        try {
            AnniversaryDto.Response response = anniversaryService.setAnniversary(
                    user.getEmail(), request.getAnniversaryDate());
            
            return ResponseEntity.ok(response);
            
        } catch (IllegalStateException e) {
            log.warn("Failed to set anniversary for user {}: {}", user.getEmail(), e.getMessage());
            return ResponseEntity.badRequest().build();
            
        } catch (Exception e) {
            log.error("Error setting anniversary for user {}: {}", user.getEmail(), e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }
    
    @GetMapping
    public ResponseEntity<AnniversaryDto.Response> getAnniversary(
            @AuthenticationPrincipal CustomOAuth2User user) {
        
        log.info("🔵 Getting anniversary for user: {}", user.getEmail());
        
        try {
            AnniversaryDto.Response response = anniversaryService.getAnniversary(user.getEmail());
            
            if (response.getAnniversaryDate() == null) {
                log.info("🟡 기념일 데이터 없음 - HTTP 204 No Content 반환");
                return ResponseEntity.noContent().build();
            }
            
            log.info("🟢 기념일 데이터 있음 - HTTP 200 OK 반환: {}", response.getAnniversaryDate());
            return ResponseEntity.ok(response);
            
        } catch (IllegalStateException e) {
            log.warn("🔴 Failed to get anniversary for user {}: {}", user.getEmail(), e.getMessage());
            return ResponseEntity.badRequest().build();
            
        } catch (Exception e) {
            log.error("🔴 Error getting anniversary for user {}: {}", user.getEmail(), e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }
    
    @PutMapping
    public ResponseEntity<AnniversaryDto.Response> updateAnniversary(
            @AuthenticationPrincipal CustomOAuth2User user,
            @Valid @RequestBody AnniversaryDto.Request request) {
        
        log.info("Updating anniversary for user: {} with date: {}", 
                user.getEmail(), request.getAnniversaryDate());
        
        try {
            AnniversaryDto.Response response = anniversaryService.updateAnniversary(
                    user.getEmail(), request.getAnniversaryDate());
            
            return ResponseEntity.ok(response);
            
        } catch (IllegalStateException e) {
            log.warn("Failed to update anniversary for user {}: {}", user.getEmail(), e.getMessage());
            return ResponseEntity.badRequest().build();
            
        } catch (Exception e) {
            log.error("Error updating anniversary for user {}: {}", user.getEmail(), e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }
    
    @DeleteMapping
    public ResponseEntity<Void> deleteAnniversary(
            @AuthenticationPrincipal CustomOAuth2User user) {
        
        log.info("Deleting anniversary for user: {}", user.getEmail());
        
        try {
            anniversaryService.deleteAnniversary(user.getEmail());
            return ResponseEntity.noContent().build();
            
        } catch (IllegalStateException e) {
            log.warn("Failed to delete anniversary for user {}: {}", user.getEmail(), e.getMessage());
            return ResponseEntity.badRequest().build();
            
        } catch (Exception e) {
            log.error("Error deleting anniversary for user {}: {}", user.getEmail(), e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }
}