package com.todayus.controller;

import com.todayus.service.DailyMessageService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/daily-message")
@RequiredArgsConstructor
public class DailyMessageController {

    private final DailyMessageService dailyMessageService;

    /**
     * 오늘의 일일 메시지 조회
     */
    @GetMapping
    public ResponseEntity<Map<String, String>> getTodaysMessage() {
        try {
            log.info("🟡 DailyMessageController - 오늘의 일일 메시지 요청 받음");

            String message = dailyMessageService.getTodaysMessage();
            log.info("🟢 DailyMessageController - 메시지 생성 완료: {}", message);

            Map<String, String> response = new HashMap<>();
            response.put("message", message);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("오늘의 일일 메시지 조회 실패: {}", e.getMessage(), e);

            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("message", "새로운 하루, 새로운 추억을 만들어보세요! ✨");

            return ResponseEntity.ok(errorResponse);
        }
    }
}