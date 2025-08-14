package com.todayus.controller;

import com.todayus.entity.Diary;
import com.todayus.repository.DiaryRepository;
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
@RequestMapping("/api/diaries")
@RequiredArgsConstructor
@Slf4j
public class DiaryImageController {

    private final S3Service s3Service;
    private final DiaryRepository diaryRepository;

    /**
     * 일기 이미지 업로드
     */
    @PostMapping("/{diaryId}/image")
    public ResponseEntity<Map<String, Object>> uploadDiaryImage(
            @PathVariable Long diaryId,
            @RequestParam("file") MultipartFile file,
            @AuthenticationPrincipal CustomOAuth2User principal) {
        
        try {
            Long userId = principal.getUserId();
            log.info("Diary image upload request for diary: {}, user: {}", diaryId, userId);

            // 일기 존재 확인 및 권한 체크
            Diary diary = diaryRepository.findById(diaryId)
                    .orElseThrow(() -> new RuntimeException("일기를 찾을 수 없습니다."));

            if (!diary.isOwnedBy(userId)) {
                throw new RuntimeException("일기 수정 권한이 없습니다.");
            }

            // 기존 이미지가 있으면 삭제
            if (diary.getImageUrl() != null && !diary.getImageUrl().isEmpty()) {
                try {
                    s3Service.deleteDiaryImage(diary.getImageUrl());
                } catch (Exception e) {
                    log.warn("Failed to delete existing diary image for diary {}: {}", diaryId, e.getMessage());
                }
            }

            // 새 이미지 업로드
            String imageUrl = s3Service.uploadDiaryImage(file, userId, diaryId);

            // 데이터베이스 업데이트
            diary.setImageUrl(imageUrl);
            diaryRepository.save(diary);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "일기 이미지가 성공적으로 업로드되었습니다.");
            response.put("imageUrl", imageUrl);

            log.info("Diary image uploaded successfully for diary {}: {}", diaryId, imageUrl);
            return ResponseEntity.ok(response);

        } catch (IllegalArgumentException e) {
            log.warn("Invalid file upload request for diary {}: {}", diaryId, e.getMessage());
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(response);

        } catch (Exception e) {
            log.error("Error uploading diary image for diary {}", diaryId, e);
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "일기 이미지 업로드 중 오류가 발생했습니다.");
            return ResponseEntity.internalServerError().body(response);
        }
    }

    /**
     * 일기 이미지 삭제
     */
    @DeleteMapping("/{diaryId}/image")
    public ResponseEntity<Map<String, Object>> deleteDiaryImage(
            @PathVariable Long diaryId,
            @AuthenticationPrincipal CustomOAuth2User principal) {
        
        try {
            Long userId = principal.getUserId();
            log.info("Diary image delete request for diary: {}, user: {}", diaryId, userId);

            // 일기 존재 확인 및 권한 체크
            Diary diary = diaryRepository.findById(diaryId)
                    .orElseThrow(() -> new RuntimeException("일기를 찾을 수 없습니다."));

            if (!diary.isOwnedBy(userId)) {
                throw new RuntimeException("일기 수정 권한이 없습니다.");
            }

            // 이미지가 있으면 삭제
            if (diary.getImageUrl() != null && !diary.getImageUrl().isEmpty()) {
                s3Service.deleteDiaryImage(diary.getImageUrl());
                
                // 데이터베이스에서 URL 제거
                diary.setImageUrl(null);
                diaryRepository.save(diary);
            }

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "일기 이미지가 삭제되었습니다.");

            log.info("Diary image deleted successfully for diary {}", diaryId);
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("Error deleting diary image for diary {}", diaryId, e);
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "일기 이미지 삭제 중 오류가 발생했습니다.");
            return ResponseEntity.internalServerError().body(response);
        }
    }

    /**
     * 일반적인 이미지 업로드 (일기 ID 없이)
     * 일기 작성 중 임시로 사용
     */
    @PostMapping("/upload-image")
    public ResponseEntity<Map<String, Object>> uploadImage(
            @RequestParam("file") MultipartFile file,
            @AuthenticationPrincipal CustomOAuth2User principal) {
        
        try {
            Long userId = principal.getUserId();
            log.info("Temporary image upload request for user: {}", userId);

            // 임시 일기 ID로 0 사용 (나중에 실제 일기 ID로 변경 가능)
            String imageUrl = s3Service.uploadDiaryImage(file, userId, 0L);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "이미지가 성공적으로 업로드되었습니다.");
            response.put("imageUrl", imageUrl);

            log.info("Temporary image uploaded successfully for user {}: {}", userId, imageUrl);
            return ResponseEntity.ok(response);

        } catch (IllegalArgumentException e) {
            log.warn("Invalid file upload request for user {}: {}", principal.getUserId(), e.getMessage());
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(response);

        } catch (Exception e) {
            log.error("Error uploading temporary image for user {}", principal.getUserId(), e);
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "이미지 업로드 중 오류가 발생했습니다.");
            return ResponseEntity.internalServerError().body(response);
        }
    }
}