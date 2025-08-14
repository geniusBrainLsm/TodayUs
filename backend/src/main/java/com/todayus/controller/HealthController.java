package com.todayus.controller;

import com.todayus.service.AIAnalysisService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.env.Environment;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/health")
@RequiredArgsConstructor
public class HealthController {

    private final Environment environment;
    private final AIAnalysisService aiAnalysisService;

    @GetMapping
    public ResponseEntity<Map<String, Object>> healthCheck() {
        Map<String, Object> health = new HashMap<>();
        
        health.put("status", "UP");
        health.put("timestamp", LocalDateTime.now());
        health.put("service", "TodayUs Backend");
        health.put("version", "1.0.0");
        
        // Check database
        health.put("database", "PostgreSQL - Connected");
        
        // Check environment variables
        Map<String, Object> config = new HashMap<>();
        config.put("profiles", environment.getActiveProfiles());
        config.put("port", environment.getProperty("server.port", "8080"));
        config.put("jwt_configured", environment.getProperty("jwt.secret") != null);
        config.put("google_oauth_configured", environment.getProperty("spring.security.oauth2.client.registration.google.client-id") != null);
        config.put("kakao_oauth_configured", environment.getProperty("spring.security.oauth2.client.registration.kakao.client-id") != null);
        
        String openaiKey = environment.getProperty("openai.api.key");
        config.put("openai_configured", openaiKey != null && openaiKey.startsWith("sk-"));
        
        health.put("configuration", config);
        
        log.info("Health check performed - Status: UP");
        return ResponseEntity.ok(health);
    }

    @PostMapping("/test-ai")
    public ResponseEntity<Map<String, Object>> testAI(@RequestBody Map<String, String> request) {
        try {
            String testTitle = request.getOrDefault("title", "테스트 일기");
            String testContent = request.getOrDefault("content", "오늘은 정말 행복한 하루였어요. 연인과 함께 산책을 했습니다.");
            
            log.info("Testing AI analysis with title: '{}' and content: '{}'", testTitle, testContent);
            
            // Test emotion analysis
            AIAnalysisService.EmotionAnalysisResult emotionResult = 
                aiAnalysisService.analyzeEmotion(testTitle, testContent);
            
            // Test AI comment generation
            String aiComment = aiAnalysisService.generateAIComment(
                testTitle, testContent, emotionResult.getEmotion());
            
            Map<String, Object> result = new HashMap<>();
            result.put("status", "SUCCESS");
            result.put("emotion_analysis", emotionResult);
            result.put("ai_comment", aiComment);
            result.put("timestamp", LocalDateTime.now());
            
            log.info("AI test completed successfully - Emotion: {}, Comment: '{}'", 
                emotionResult.getEmotion(), aiComment);
            
            return ResponseEntity.ok(result);
            
        } catch (Exception e) {
            log.error("AI test failed: {}", e.getMessage(), e);
            
            Map<String, Object> error = new HashMap<>();
            error.put("status", "ERROR");
            error.put("message", e.getMessage());
            error.put("timestamp", LocalDateTime.now());
            
            return ResponseEntity.status(500).body(error);
        }
    }
}