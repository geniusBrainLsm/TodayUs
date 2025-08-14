package com.todayus.controller;

import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/cors-test")
@Slf4j
@CrossOrigin(origins = "*", allowedHeaders = "*")
public class CorsTestController {

    /**
     * CORS 테스트용 단순 GET 엔드포인트
     */
    @GetMapping("/simple")
    public ResponseEntity<Map<String, Object>> simpleTest() {
        Map<String, Object> response = new HashMap<>();
        response.put("message", "CORS GET 테스트 성공!");
        response.put("timestamp", System.currentTimeMillis());
        response.put("status", "success");
        
        log.info("CORS GET 테스트 요청 받음");
        return ResponseEntity.ok(response);
    }

    /**
     * CORS 테스트용 POST 엔드포인트 (Preflight 테스트)
     */
    @PostMapping("/preflight")
    public ResponseEntity<Map<String, Object>> preflightTest(@RequestBody Map<String, Object> requestData) {
        Map<String, Object> response = new HashMap<>();
        response.put("message", "CORS POST 테스트 성공!");
        response.put("receivedData", requestData);
        response.put("timestamp", System.currentTimeMillis());
        response.put("status", "success");
        
        log.info("CORS POST 테스트 요청 받음: {}", requestData);
        return ResponseEntity.ok(response);
    }

    /**
     * 인증이 필요한 CORS 테스트
     */
    @GetMapping("/auth")
    public ResponseEntity<Map<String, Object>> authTest() {
        Map<String, Object> response = new HashMap<>();
        response.put("message", "인증된 CORS 테스트 성공!");
        response.put("timestamp", System.currentTimeMillis());
        response.put("status", "success");
        
        log.info("인증된 CORS 테스트 요청 받음");
        return ResponseEntity.ok(response);
    }

    /**
     * OPTIONS 요청 처리 (수동 처리)
     */
    @RequestMapping(value = "/**", method = RequestMethod.OPTIONS)
    public ResponseEntity<Void> handleOptions() {
        log.info("OPTIONS 요청 처리됨");
        return ResponseEntity.ok().build();
    }
}