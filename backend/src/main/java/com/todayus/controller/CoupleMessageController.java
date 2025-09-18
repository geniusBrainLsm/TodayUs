package com.todayus.controller;

import com.todayus.dto.CoupleMessageDto;
import com.todayus.security.CustomOAuth2User;
import com.todayus.service.CoupleMessageService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Slf4j
@RestController
@RequestMapping("/api/couple-messages")
@RequiredArgsConstructor
public class CoupleMessageController {

    private final CoupleMessageService coupleMessageService;
    
    /**
     * 새로운 대신 전달하기 메시지 생성
     */
    @PostMapping
    public ResponseEntity<?> createMessage(
            @AuthenticationPrincipal CustomOAuth2User user,
            @Valid @RequestBody CoupleMessageDto.CreateRequest request) {
        try {
            CoupleMessageDto.Response response = coupleMessageService.createMessage(user.getEmail(), request);

            log.info("대신 전달하기 메시지 생성 완료: {}", response.getId());
            return ResponseEntity.ok(response);

        } catch (IllegalStateException e) {
            log.warn("대신 전달하기 메시지 생성 실패: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            log.error("대신 전달하기 메시지 생성 오류", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "메시지 생성에 실패했습니다."));
        }
    }
    
    /**
     * 로그인 시 받을 메시지 확인 (팝업용)
     */
    @GetMapping("/popup")
    public ResponseEntity<?> getMessageForPopup(@AuthenticationPrincipal CustomOAuth2User user) {
        try {
            Optional<CoupleMessageDto.PopupResponse> messageOpt =
                    coupleMessageService.getMessageForPopup(user.getEmail());

            if (messageOpt.isPresent()) {
                log.info("사용자 {}에게 전달할 메시지 발견", user.getEmail());
                return ResponseEntity.ok(messageOpt.get());
            } else {
                return ResponseEntity.ok(Map.of("hasMessage", false));
            }

        } catch (Exception e) {
            log.error("팝업 메시지 조회 오류", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "메시지 조회에 실패했습니다."));
        }
    }
    
    /**
     * 메시지를 전달됨 상태로 변경 (팝업 표시 후)
     */
    @PutMapping("/{messageId}/delivered")
    public ResponseEntity<?> markAsDelivered(
            @PathVariable Long messageId,
            @AuthenticationPrincipal CustomOAuth2User user) {
        try {
            coupleMessageService.markMessageAsDelivered(messageId, user.getEmail());

            log.info("메시지 {} 전달 완료", messageId);
            return ResponseEntity.ok(Map.of("message", "메시지가 전달되었습니다."));

        } catch (IllegalArgumentException e) {
            log.warn("메시지 전달 처리 실패: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            log.error("메시지 전달 처리 오류", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "메시지 전달 처리에 실패했습니다."));
        }
    }
    
    /**
     * 메시지를 읽음 상태로 변경
     */
    @PutMapping("/{messageId}/read")
    public ResponseEntity<?> markAsRead(
            @PathVariable Long messageId,
            @AuthenticationPrincipal CustomOAuth2User user) {
        try {
            coupleMessageService.markMessageAsRead(messageId, user.getEmail());

            log.info("메시지 {} 읽음 완료", messageId);
            return ResponseEntity.ok(Map.of("message", "메시지를 읽었습니다."));

        } catch (IllegalArgumentException e) {
            log.warn("메시지 읽음 처리 실패: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            log.error("메시지 읽음 처리 오류", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "메시지 읽음 처리에 실패했습니다."));
        }
    }
    
    /**
     * 주간 사용량 조회
     */
    @GetMapping("/weekly-usage")
    public ResponseEntity<?> getWeeklyUsage(@AuthenticationPrincipal CustomOAuth2User user) {
        try {
            CoupleMessageDto.WeeklyUsage usage = coupleMessageService.getWeeklyUsage(user.getEmail());

            return ResponseEntity.ok(usage);

        } catch (Exception e) {
            log.error("주간 사용량 조회 오류", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "사용량 조회에 실패했습니다."));
        }
    }
    
    /**
     * 메시지 히스토리 조회
     */
    @GetMapping("/history")
    public ResponseEntity<?> getMessageHistory(@AuthenticationPrincipal CustomOAuth2User user) {
        try {
            List<CoupleMessageDto.Response> history = coupleMessageService.getMessageHistory(user.getEmail());

            return ResponseEntity.ok(Map.of("messages", history));

        } catch (Exception e) {
            log.error("메시지 히스토리 조회 오류", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "히스토리 조회에 실패했습니다."));
        }
    }
    
}