package com.todayus.config;

import org.springframework.cache.CacheManager;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.cache.concurrent.ConcurrentMapCache;
import org.springframework.cache.support.SimpleCacheManager;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.Arrays;

/**
 * 로봇 정보 캐싱 설정
 * - 로봇 정보는 자주 변경되지 않으므로 메모리 캐시로 성능 최적화
 * - 이미지 URL 등도 함께 캐시되어 매번 DB 조회 불필요
 */
@Configuration
@EnableCaching
public class CacheConfig {

    @Bean
    public CacheManager cacheManager() {
        SimpleCacheManager cacheManager = new SimpleCacheManager();
        cacheManager.setCaches(Arrays.asList(
                // 로봇 정보 캐시 (ID별)
                new ConcurrentMapCache("robotInfo"),
                // 커플의 활성 로봇 캐시 (coupleId별)
                new ConcurrentMapCache("coupleActiveRobot")
        ));
        return cacheManager;
    }
}
