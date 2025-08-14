package com.todayus.controller;

import com.todayus.security.CustomOAuth2User;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/upload")
public class FileUploadController {

    @Value("${app.upload.dir:uploads}")
    private String uploadDir;

    @PostMapping("/image")
    public ResponseEntity<Map<String, String>> uploadImage(
            @AuthenticationPrincipal CustomOAuth2User user,
            @RequestParam("image") MultipartFile file) {
        
        log.info("Uploading image for user: {}", user.getEmail());
        
        try {
            // 파일 검증
            if (file.isEmpty()) {
                throw new IllegalArgumentException("파일이 선택되지 않았습니다.");
            }
            
            String contentType = file.getContentType();
            if (contentType == null || !contentType.startsWith("image/")) {
                throw new IllegalArgumentException("이미지 파일만 업로드 가능합니다.");
            }
            
            // 파일 크기 제한 (5MB)
            if (file.getSize() > 5 * 1024 * 1024) {
                throw new IllegalArgumentException("파일 크기는 5MB를 초과할 수 없습니다.");
            }
            
            // 업로드 디렉토리 생성
            Path uploadPath = Paths.get(uploadDir);
            if (!Files.exists(uploadPath)) {
                Files.createDirectories(uploadPath);
            }
            
            // 고유한 파일명 생성
            String originalFilename = file.getOriginalFilename();
            String extension = "";
            if (originalFilename != null && originalFilename.contains(".")) {
                extension = originalFilename.substring(originalFilename.lastIndexOf("."));
            }
            String filename = UUID.randomUUID().toString() + extension;
            
            // 파일 저장
            Path filePath = uploadPath.resolve(filename);
            Files.copy(file.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);
            
            // URL 생성 (실제 환경에서는 도메인명을 사용)
            String imageUrl = "/uploads/" + filename;
            
            Map<String, String> response = new HashMap<>();
            response.put("imageUrl", imageUrl);
            response.put("filename", filename);
            
            log.info("Image uploaded successfully: {}", imageUrl);
            return ResponseEntity.ok(response);
            
        } catch (IllegalArgumentException e) {
            log.warn("Invalid file upload request: {}", e.getMessage());
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(error);
            
        } catch (IOException e) {
            log.error("Error uploading file: {}", e.getMessage(), e);
            Map<String, String> error = new HashMap<>();
            error.put("error", "파일 업로드 중 오류가 발생했습니다.");
            return ResponseEntity.internalServerError().body(error);
        }
    }
}