package com.todayus.controller;

import com.todayus.dto.BoardDto;
import com.todayus.security.CustomOAuth2User;
import com.todayus.service.BoardService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@Slf4j
@RestController
@RequestMapping("/api/admin/boards")
@RequiredArgsConstructor
public class AdminBoardController {

    private final BoardService boardService;

    /**
     * 관리자: 모든 게시글 조회
     */
    @GetMapping
    public ResponseEntity<Page<BoardDto.Response>> getAllBoards(
            @AuthenticationPrincipal CustomOAuth2User user,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        log.info("관리자 게시글 전체 조회: user={}, page={}, size={}", user.getEmail(), page, size);

        try {
            Page<BoardDto.Response> response = boardService.getAllBoardsForAdmin(user.getEmail(), page, size);
            return ResponseEntity.ok(response);
        } catch (IllegalStateException e) {
            log.warn("권한 없음: {}", e.getMessage());
            return ResponseEntity.status(403).build();
        } catch (Exception e) {
            log.error("게시글 조회 오류: {}", e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * 관리자: 게시글 고정/해제
     */
    @PostMapping("/{boardId}/pin")
    public ResponseEntity<BoardDto.Response> togglePin(
            @AuthenticationPrincipal CustomOAuth2User user,
            @PathVariable Long boardId) {

        log.info("게시글 고정 토글: user={}, boardId={}", user.getEmail(), boardId);

        try {
            BoardDto.Response response = boardService.togglePin(user.getEmail(), boardId);
            return ResponseEntity.ok(response);
        } catch (IllegalStateException e) {
            log.warn("권한 없음: {}", e.getMessage());
            return ResponseEntity.status(403).build();
        } catch (IllegalArgumentException e) {
            log.warn("게시글 없음: {}", e.getMessage());
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            log.error("게시글 고정 오류: {}", e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * 관리자: 게시글 수정 (상태 포함)
     */
    @PutMapping("/{boardId}")
    public ResponseEntity<BoardDto.Response> updateBoard(
            @AuthenticationPrincipal CustomOAuth2User user,
            @PathVariable Long boardId,
            @Valid @RequestBody BoardDto.AdminUpdateRequest request) {

        log.info("관리자 게시글 수정: user={}, boardId={}", user.getEmail(), boardId);

        try {
            BoardDto.Response response = boardService.updateBoardStatus(user.getEmail(), boardId, request);
            return ResponseEntity.ok(response);
        } catch (IllegalStateException e) {
            log.warn("권한 없음: {}", e.getMessage());
            return ResponseEntity.status(403).build();
        } catch (IllegalArgumentException e) {
            log.warn("게시글 없음: {}", e.getMessage());
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            log.error("게시글 수정 오류: {}", e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * 관리자: 게시글에 답변 등록
     */
    @PostMapping("/{boardId}/reply")
    public ResponseEntity<BoardDto.Response> replyToBoard(
            @AuthenticationPrincipal CustomOAuth2User user,
            @PathVariable Long boardId,
            @RequestBody BoardDto.AdminReplyRequest request) {

        log.info("관리자 답변 등록: user={}, boardId={}", user.getEmail(), boardId);

        try {
            BoardDto.Response response = boardService.replyToBoard(user.getEmail(), boardId, request);
            return ResponseEntity.ok(response);
        } catch (IllegalStateException e) {
            log.warn("권한 없음: {}", e.getMessage());
            return ResponseEntity.status(403).build();
        } catch (IllegalArgumentException e) {
            log.warn("게시글 없음: {}", e.getMessage());
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            log.error("답변 등록 오류: {}", e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }
}
