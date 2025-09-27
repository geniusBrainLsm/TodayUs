package com.todayus.controller;

import com.todayus.entity.Diary;
import com.todayus.repository.DiaryRepository;
import com.todayus.security.CustomOAuth2User;
import com.todayus.service.S3Service;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
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
     * ?쇨린 ?대?吏 ?낅줈??
     */
    @PostMapping("/{diaryId}/image")
    public ResponseEntity<Map<String, Object>> uploadDiaryImage(

            @PathVariable Long diaryId,

            @RequestParam("file") MultipartFile file,

            @AuthenticationPrincipal CustomOAuth2User principal) {

        Long userId = principal != null ? principal.getUserId() : null;

        if (userId == null) {

            Map<String, Object> response = new HashMap<>();

            response.put("success", false);

            response.put("message", "Authentication required.");

            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);

        }

        try {

            log.info("Diary image upload request for diary: {}, user: {}", diaryId, userId);

            Diary diary = diaryRepository.findById(diaryId)

                    .orElseThrow(() -> new RuntimeException("?�기�?찾을 ???�습?�다."));

            if (!diary.isOwnedBy(userId)) {

                throw new RuntimeException("?�기 ?�정 권한???�습?�다.");

            }

            if (diary.getImageUrl() != null && !diary.getImageUrl().isEmpty()) {

                try {

                    s3Service.deleteDiaryImage(diary.getImageUrl());

                } catch (Exception e) {

                    log.warn("Failed to delete existing diary image for diary {}: {}", diaryId, e.getMessage());

                }

            }

            String imageUrl = s3Service.uploadDiaryImage(file, userId, diaryId);

            diary.setImageUrl(imageUrl);

            diaryRepository.save(diary);

            Map<String, Object> response = new HashMap<>();

            response.put("success", true);

            response.put("message", "?�기 ?��?지가 ?�공?�으�??�로?�되?�습?�다.");

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

            response.put("message", "?�기 ?��?지 ?�로??�??�류가 발생?�습?�다.");

            return ResponseEntity.internalServerError().body(response);

        }

    }



    /**
     * ?쇨린 ?대?吏 ??젣
     */
    @DeleteMapping("/{diaryId}/image")
    public ResponseEntity<Map<String, Object>> deleteDiaryImage(
            @PathVariable Long diaryId,
            @AuthenticationPrincipal CustomOAuth2User principal) {
        Long userId = principal != null ? principal.getUserId() : null;
        if (userId == null) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Authentication required.");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
        }
        try {
            log.info("Diary image delete request for diary: {}, user: {}", diaryId, userId);
            Diary diary = diaryRepository.findById(diaryId)
                    .orElseThrow(() -> new RuntimeException("?�기�?찾을 ???�습?�다."));
            if (!diary.isOwnedBy(userId)) {
                throw new RuntimeException("?�기 ?�정 권한???�습?�다.");
            }
            if (diary.getImageUrl() != null && !diary.getImageUrl().isEmpty()) {
                s3Service.deleteDiaryImage(diary.getImageUrl());
                diary.setImageUrl(null);
                diaryRepository.save(diary);
            }
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "?�기 ?��?지가 ??��?�었?�니??");
            log.info("Diary image deleted successfully for diary {}", diaryId);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Error deleting diary image for diary {}", diaryId, e);
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "?�기 ?��?지 ??�� �??�류가 발생?�습?�다.");
            return ResponseEntity.internalServerError().body(response);
        }
    }


    /**
     * ?쇰컲?곸씤 ?대?吏 ?낅줈??(?쇨린 ID ?놁씠)
     * ?쇨린 ?묒꽦 以??꾩떆濡??ъ슜
     */
    @PostMapping("/upload-image")

    public ResponseEntity<Map<String, Object>> uploadImage(

            @RequestParam("file") MultipartFile file,

            @AuthenticationPrincipal CustomOAuth2User principal) {

        Long userId = principal != null ? principal.getUserId() : null;

        if (userId == null) {

            Map<String, Object> response = new HashMap<>();

            response.put("success", false);

            response.put("message", "Authentication required.");

            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);

        }

        try {

            log.info("Temporary image upload request for user: {}", userId);

            // ?�시 ?�기 ID�?0 ?�용 (?�중???�제 ?�기 ID�?변�?가??

            String imageUrl = s3Service.uploadDiaryImage(file, userId, 0L);

            Map<String, Object> response = new HashMap<>();

            response.put("success", true);

            response.put("message", "?��?지가 ?�공?�으�??�로?�되?�습?�다.");

            response.put("imageUrl", imageUrl);

            log.info("Temporary image uploaded successfully for user {}: {}", userId, imageUrl);

            return ResponseEntity.ok(response);

        } catch (IllegalArgumentException e) {

            log.warn("Invalid file upload request for user {}: {}", userId, e.getMessage());

            Map<String, Object> response = new HashMap<>();

            response.put("success", false);

            response.put("message", e.getMessage());

            return ResponseEntity.badRequest().body(response);

        } catch (Exception e) {

            log.error("Error uploading temporary image for user {}", userId, e);

            Map<String, Object> response = new HashMap<>();

            response.put("success", false);

            response.put("message", "?��?지 ?�로??�??�류가 발생?�습?�다.");

            return ResponseEntity.internalServerError().body(response);

        }

    }








}


