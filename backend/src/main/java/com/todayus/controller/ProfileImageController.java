package com.todayus.controller;

import com.todayus.entity.User;
import com.todayus.repository.UserRepository;
import com.todayus.security.CustomOAuth2User;
import com.todayus.service.S3Service;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/profile")
@RequiredArgsConstructor
@Slf4j
public class ProfileImageController {

    private final S3Service s3Service;
    private final UserRepository userRepository;

    /**
     * 프로필 이미지 업로드
     */
    @PostMapping("/image")
    public ResponseEntity<Map<String, Object>> uploadProfileImage(
            @RequestParam("file") MultipartFile file,
            @AuthenticationPrincipal CustomOAuth2User principal) {
        
        try {
            Long userId = principal.getUserId();
            log.info("Profile image upload request for user: {}", userId);

            // 사용자 정보 조회
            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));

            // 기존 프로필 이미지가 있으면 삭제
            if (user.getProfileImageUrl() != null && !user.getProfileImageUrl().isEmpty()) {
                try {
                    s3Service.deleteProfileImage(user.getProfileImageUrl());
                } catch (Exception e) {
                    log.warn("Failed to delete existing profile image for user {}: {}", userId, e.getMessage());
                }
            }

            // 새 이미지 업로드
            String imageUrl = s3Service.uploadProfileImage(file, userId);

            // 데이터베이스 업데이트
            user.setProfileImageUrl(imageUrl);
            userRepository.save(user);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "프로필 이미지가 성공적으로 업로드되었습니다.");
            response.put("profileImageUrl", imageUrl);

            log.info("Profile image uploaded successfully for user {}: {}", userId, imageUrl);
            return ResponseEntity.ok(response);

        } catch (IllegalArgumentException e) {
            log.warn("Invalid file upload request: {}", e.getMessage());
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(response);

        } catch (Exception e) {
            log.error("Error uploading profile image", e);
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "프로필 이미지 업로드 중 오류가 발생했습니다.");
            return ResponseEntity.internalServerError().body(response);
        }
    }

    /**
     * 프로필 이미지 삭제
     */
    @DeleteMapping("/image")
    public ResponseEntity<Map<String, Object>> deleteProfileImage(
            @AuthenticationPrincipal CustomOAuth2User principal) {
        
        try {
            Long userId = principal.getUserId();
            log.info("Profile image delete request for user: {}", userId);

            // 사용자 정보 조회
            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));

            // 프로필 이미지가 있으면 삭제
            if (user.getProfileImageUrl() != null && !user.getProfileImageUrl().isEmpty()) {
                s3Service.deleteProfileImage(user.getProfileImageUrl());
                
                // 데이터베이스에서 URL 제거
                user.setProfileImageUrl(null);
                userRepository.save(user);
            }

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "프로필 이미지가 삭제되었습니다.");

            log.info("Profile image deleted successfully for user {}", userId);
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("Error deleting profile image", e);
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "프로필 이미지 삭제 중 오류가 발생했습니다.");
            return ResponseEntity.internalServerError().body(response);
        }
    }

    /**
     * 현재 프로필 이미지 URL 조회
     */
    @GetMapping("/image")
    public ResponseEntity<Map<String, Object>> getProfileImage(
            @AuthenticationPrincipal CustomOAuth2User principal) {
        
        try {
            Long userId = principal.getUserId();
            
            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("profileImageUrl", user.getProfileImageUrl());

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("Error getting profile image", e);
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "프로필 이미지 조회 중 오류가 발생했습니다.");
            return ResponseEntity.internalServerError().body(response);
        }
    }
}