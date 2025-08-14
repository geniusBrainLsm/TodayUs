package com.todayus.config;

import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class EnvironmentConfig {

    private final Environment environment;

    public EnvironmentConfig(Environment environment) {
        this.environment = environment;
    }

    @EventListener(ApplicationReadyEvent.class)
    public void logEnvironmentInfo() {
        log.info("============================================");
        log.info("    TodayUs Backend Configuration");
        log.info("============================================");
        
        // Database
        log.info("🗄️  Database Configuration:");
        log.info("   - URL: {}", environment.getProperty("spring.datasource.url"));
        log.info("   - Username: {}", environment.getProperty("spring.datasource.username"));
        log.info("   - Driver: {}", environment.getProperty("spring.datasource.driver-class-name"));
        
        // OAuth2
        log.info("🔐 OAuth2 Configuration:");
        String googleClientId = environment.getProperty("spring.security.oauth2.client.registration.google.client-id");
        String kakaoClientId = environment.getProperty("spring.security.oauth2.client.registration.kakao.client-id");
        log.info("   - Google Client ID: {}****", googleClientId != null ? googleClientId.substring(0, Math.min(12, googleClientId.length())) : "NOT_SET");
        log.info("   - Kakao Client ID: {}****", kakaoClientId != null ? kakaoClientId.substring(0, Math.min(12, kakaoClientId.length())) : "NOT_SET");
        
        // JWT
        log.info("🔑 JWT Configuration:");
        String jwtSecret = environment.getProperty("jwt.secret");
        log.info("   - Secret: {}****", jwtSecret != null ? jwtSecret.substring(0, Math.min(8, jwtSecret.length())) : "NOT_SET");
        log.info("   - Validity: {} seconds", environment.getProperty("jwt.token-validity-in-seconds"));
        
        // OpenAI
        log.info("🤖 OpenAI Configuration:");
        String openaiKey = environment.getProperty("openai.api.key");
        if (openaiKey != null && openaiKey.startsWith("sk-")) {
            log.info("   - API Key: sk-****{}", openaiKey.substring(openaiKey.length() - 4));
            log.info("   - Status: ✅ CONFIGURED");
        } else {
            log.info("   - Status: ❌ NOT CONFIGURED");
        }
        
        // Server
        log.info("🚀 Server Configuration:");
        log.info("   - Port: {}", environment.getProperty("server.port", "8080"));
        log.info("   - Profile: {}", String.join(", ", environment.getActiveProfiles()));
        
        log.info("============================================");
        log.info("🎉 TodayUs Backend is ready for production!");
        log.info("============================================");
    }
}