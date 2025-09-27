package com.todayus.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.GetUrlRequest;
import software.amazon.awssdk.services.s3.model.ObjectCannedACL;
import software.amazon.awssdk.services.s3.model.PutObjectAclRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.model.S3Exception;

import java.io.IOException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class S3Service {

    private final S3Client s3Client;

    @Value("${aws.s3.bucket}")
    private String bucketName;

    @Value("${aws.s3.profile-image-path:profile-images/}")
    private String profileImagePath;

    @Value("${aws.s3.diary-image-path:diary-images/}")
    private String diaryImagePath;

    private static final List<String> ALLOWED_EXTENSIONS = Arrays.asList("jpg", "jpeg", "png", "gif", "webp");
    private static final long MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB (일기 사진은 좀 더 크게)

    /**
     * 프로필 이미지 업로드
     */
    public String uploadProfileImage(MultipartFile file, Long userId) {
        validateFile(file);

        String fileName = generateFileName(file.getOriginalFilename(), userId);
        String key = profileImagePath + fileName;

        try {
            PutObjectRequest putObjectRequest = PutObjectRequest.builder()
                    .bucket(bucketName)
                    .key(key)
                    .contentType(file.getContentType())
                    .contentLength(file.getSize())
                    .acl(ObjectCannedACL.PUBLIC_READ)
                    .build();

            s3Client.putObject(putObjectRequest, RequestBody.fromInputStream(file.getInputStream(), file.getSize()));
            applyPublicReadAcl(key);

            String imageUrl = getPublicUrl(key);
            log.info("Profile image uploaded successfully for user {}: {}", userId, imageUrl);
            return imageUrl;

        } catch (S3Exception e) {
            log.error("S3 error while uploading profile image for user {}: {}", userId, e.getMessage(), e);
            throw new RuntimeException("S3 업로드 중 오류가 발생했습니다: " + e.getMessage());
        } catch (IOException e) {
            log.error("IO error while uploading profile image for user {}: {}", userId, e.getMessage(), e);
            throw new RuntimeException("파일 읽기 중 오류가 발생했습니다: " + e.getMessage());
        }
    }

    /**
     * 프로필 이미지 삭제
     */
    public void deleteProfileImage(String imageUrl) {
        try {
            String key = extractKeyFromUrl(imageUrl);
            if (key != null && key.startsWith(profileImagePath)) {
                DeleteObjectRequest deleteObjectRequest = DeleteObjectRequest.builder()
                        .bucket(bucketName)
                        .key(key)
                        .build();

                s3Client.deleteObject(deleteObjectRequest);
                log.info("Profile image deleted successfully: {}", imageUrl);
            }
        } catch (S3Exception e) {
            log.error("S3 error while deleting profile image {}: {}", imageUrl, e.getMessage(), e);
            throw new RuntimeException("S3 삭제 중 오류가 발생했습니다: " + e.getMessage());
        }
    }

    /**
     * 일기 이미지 업로드
     */
    public String uploadDiaryImage(MultipartFile file, Long userId, Long diaryId) {
        validateFile(file);

        String fileName = generateDiaryImageFileName(file.getOriginalFilename(), userId, diaryId);
        String key = diaryImagePath + fileName;

        try {
            PutObjectRequest putObjectRequest = PutObjectRequest.builder()
                    .bucket(bucketName)
                    .key(key)
                    .contentType(file.getContentType())
                    .contentLength(file.getSize())
                    .acl(ObjectCannedACL.PUBLIC_READ)
                    .build();

            s3Client.putObject(putObjectRequest, RequestBody.fromInputStream(file.getInputStream(), file.getSize()));
            applyPublicReadAcl(key);

            String imageUrl = getPublicUrl(key);
            log.info("Diary image uploaded successfully for user {} diary {}: {}", userId, diaryId, imageUrl);
            return imageUrl;

        } catch (S3Exception e) {
            log.error("S3 error while uploading diary image for user {} diary {}: {}", userId, diaryId, e.getMessage(), e);
            throw new RuntimeException("S3 업로드 중 오류가 발생했습니다: " + e.getMessage());
        } catch (IOException e) {
            log.error("IO error while uploading diary image for user {} diary {}: {}", userId, diaryId, e.getMessage(), e);
            throw new RuntimeException("파일 읽기 중 오류가 발생했습니다: " + e.getMessage());
        }
    }

    /**
     * 일기 이미지 삭제
     */
    public String uploadTemporaryDiaryImage(MultipartFile file, Long userId) {
        return uploadDiaryImage(file, userId, 0L);
    }

    public void deleteDiaryImage(String imageUrl) {
        try {
            String key = extractKeyFromUrl(imageUrl);
            if (key != null && key.startsWith(diaryImagePath)) {
                DeleteObjectRequest deleteObjectRequest = DeleteObjectRequest.builder()
                        .bucket(bucketName)
                        .key(key)
                        .build();

                s3Client.deleteObject(deleteObjectRequest);
                log.info("Diary image deleted successfully: {}", imageUrl);
            }
        } catch (S3Exception e) {
            log.error("S3 error while deleting diary image {}: {}", imageUrl, e.getMessage(), e);
            throw new RuntimeException("S3 삭제 중 오류가 발생했습니다: " + e.getMessage());
        }
    }

    /**
     * 파일 유효성 검증
     */
    private void validateFile(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("파일이 비어있습니다.");
        }

        if (file.getSize() > MAX_FILE_SIZE) {
            throw new IllegalArgumentException("파일 크기는 5MB를 초과할 수 없습니다.");
        }

        String originalFilename = file.getOriginalFilename();
        if (originalFilename == null) {
            throw new IllegalArgumentException("파일명이 없습니다.");
        }

        String extension = getFileExtension(originalFilename);
        if (!ALLOWED_EXTENSIONS.contains(extension.toLowerCase())) {
            throw new IllegalArgumentException("허용되지 않은 파일 형식입니다. 허용 형식: " + String.join(", ", ALLOWED_EXTENSIONS));
        }

        String contentType = file.getContentType();
        if (contentType == null || !contentType.startsWith("image/")) {
            throw new IllegalArgumentException("이미지 파일만 업로드할 수 있습니다.");
        }
    }

    /**
     * 고유한 파일명 생성 (프로필용)
     */
    private String generateFileName(String originalFilename, Long userId) {
        String extension = getFileExtension(originalFilename);
        String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss"));
        String uniqueId = UUID.randomUUID().toString().substring(0, 8);
        return String.format("user_%d_%s_%s.%s", userId, timestamp, uniqueId, extension);
    }

    /**
     * 일기 이미지용 파일명 생성
     */
    private String generateDiaryImageFileName(String originalFilename, Long userId, Long diaryId) {
        String extension = getFileExtension(originalFilename);
        String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss"));
        String uniqueId = UUID.randomUUID().toString().substring(0, 8);
        return String.format("diary_%d_user_%d_%s_%s.%s", diaryId, userId, timestamp, uniqueId, extension);
    }

    /**
     * 파일 확장자 추출
     */
    private String getFileExtension(String filename) {
        int lastDotIndex = filename.lastIndexOf(".");
        if (lastDotIndex == -1 || lastDotIndex == filename.length() - 1) {
            throw new IllegalArgumentException("파일 확장자를 찾을 수 없습니다.");
        }
        return filename.substring(lastDotIndex + 1);
    }

    /**
     * S3 객체의 공개 URL 생성
     */
    private void applyPublicReadAcl(String key) {
        try {
            PutObjectAclRequest aclRequest = PutObjectAclRequest.builder()
                    .bucket(bucketName)
                    .key(key)
                    .acl(ObjectCannedACL.PUBLIC_READ)
                    .build();
            s3Client.putObjectAcl(aclRequest);
        } catch (S3Exception e) {
            log.warn("Failed to set public-read ACL for {}: {}", key, e.getMessage());
        }
    }

    private String getPublicUrl(String key) {
        GetUrlRequest getUrlRequest = GetUrlRequest.builder()
                .bucket(bucketName)
                .key(key)
                .build();

        return s3Client.utilities().getUrl(getUrlRequest).toString();
    }

    /**
     * URL에서 S3 키 추출
     */
    private String extractKeyFromUrl(String url) {
        try {
            // URL 형태: https://bucket-name.s3.region.amazonaws.com/key
            // 또는: https://s3.region.amazonaws.com/bucket-name/key
            String[] parts = url.split("/");
            if (parts.length >= 4) {
                // 세 번째 슬래시 이후의 모든 부분을 키로 간주
                StringBuilder keyBuilder = new StringBuilder();
                for (int i = 3; i < parts.length; i++) {
                    if (i > 3) keyBuilder.append("/");
                    keyBuilder.append(parts[i]);
                }
                return keyBuilder.toString();
            }
        } catch (Exception e) {
            log.warn("Failed to extract key from URL: {}", url, e);
        }
        return null;
    }
}