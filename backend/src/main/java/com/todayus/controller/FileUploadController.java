package com.todayus.controller;

import com.todayus.security.CustomOAuth2User;
import com.todayus.service.S3Service;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.util.HashMap;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/upload")
@RequiredArgsConstructor
public class FileUploadController {

    private final S3Service s3Service;

    @PostMapping("/image")
    public ResponseEntity<Map<String, String>> uploadImage(
            @AuthenticationPrincipal CustomOAuth2User user,
            @RequestParam("image") MultipartFile file) {

        if (user == null) {
            Map<String, String> error = new HashMap<>();
            error.put("error", "Authentication required.");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(error);
        }

        Long userId = user.getUserId();
        log.info("Uploading image for user: {}", user.getEmail());

        try {
            String imageUrl = s3Service.uploadTemporaryDiaryImage(file, userId);

            Map<String, String> response = new HashMap<>();
            response.put("imageUrl", imageUrl);
            response.put("filename", extractFilename(imageUrl));

            log.info("Image uploaded successfully to S3: {}", imageUrl);
            return ResponseEntity.ok(response);

        } catch (IllegalArgumentException e) {
            log.warn("Invalid file upload request: {}", e.getMessage());
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(error);

        } catch (Exception e) {
            log.error("Error uploading file to S3: {}", e.getMessage(), e);
            Map<String, String> error = new HashMap<>();
            error.put("error", "Image upload failed due to server error.");
            return ResponseEntity.internalServerError().body(error);
        }
    }

    private String extractFilename(String imageUrl) {
        if (imageUrl == null || imageUrl.isEmpty()) {
            return imageUrl;
        }
        int lastSlashIndex = imageUrl.lastIndexOf('/');
        if (lastSlashIndex == -1 || lastSlashIndex == imageUrl.length() - 1) {
            return imageUrl;
        }
        return imageUrl.substring(lastSlashIndex + 1);
    }
}
