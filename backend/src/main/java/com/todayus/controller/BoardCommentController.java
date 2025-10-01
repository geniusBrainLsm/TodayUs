package com.todayus.controller;

import com.todayus.dto.BoardCommentDto;
import com.todayus.security.CustomOAuth2User;
import com.todayus.service.BoardCommentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api/boards/{boardId}/comments")
@RequiredArgsConstructor
public class BoardCommentController {

    private final BoardCommentService commentService;

    /**
     * 댓글 목록 조회
     */
    @GetMapping
    public ResponseEntity<List<BoardCommentDto.Response>> getComments(@PathVariable Long boardId) {
        log.info("댓글 목록 조회: boardId={}", boardId);

        try {
            List<BoardCommentDto.Response> comments = commentService.getComments(boardId);
            return ResponseEntity.ok(comments);
        } catch (Exception e) {
            log.error("댓글 목록 조회 오류: {}", e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * 댓글 작성
     */
    @PostMapping
    public ResponseEntity<BoardCommentDto.Response> createComment(
            @AuthenticationPrincipal CustomOAuth2User user,
            @PathVariable Long boardId,
            @Valid @RequestBody BoardCommentDto.CreateRequest request) {

        log.info("댓글 작성: user={}, boardId={}", user.getEmail(), boardId);

        try {
            BoardCommentDto.Response response = commentService.createComment(user.getEmail(), boardId, request);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            log.warn("게시글 없음: {}", e.getMessage());
            return ResponseEntity.notFound().build();
        } catch (IllegalStateException e) {
            log.warn("권한 없음: {}", e.getMessage());
            return ResponseEntity.status(403).build();
        } catch (Exception e) {
            log.error("댓글 작성 오류: {}", e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * 댓글 수정
     */
    @PutMapping("/{commentId}")
    public ResponseEntity<BoardCommentDto.Response> updateComment(
            @AuthenticationPrincipal CustomOAuth2User user,
            @PathVariable Long boardId,
            @PathVariable Long commentId,
            @Valid @RequestBody BoardCommentDto.UpdateRequest request) {

        log.info("댓글 수정: user={}, commentId={}", user.getEmail(), commentId);

        try {
            BoardCommentDto.Response response = commentService.updateComment(user.getEmail(), commentId, request);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            log.warn("댓글 없음: {}", e.getMessage());
            return ResponseEntity.notFound().build();
        } catch (IllegalStateException e) {
            log.warn("권한 없음: {}", e.getMessage());
            return ResponseEntity.status(403).build();
        } catch (Exception e) {
            log.error("댓글 수정 오류: {}", e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * 댓글 삭제
     */
    @DeleteMapping("/{commentId}")
    public ResponseEntity<Void> deleteComment(
            @AuthenticationPrincipal CustomOAuth2User user,
            @PathVariable Long boardId,
            @PathVariable Long commentId) {

        log.info("댓글 삭제: user={}, commentId={}", user.getEmail(), commentId);

        try {
            commentService.deleteComment(user.getEmail(), commentId);
            return ResponseEntity.noContent().build();
        } catch (IllegalArgumentException e) {
            log.warn("댓글 없음: {}", e.getMessage());
            return ResponseEntity.notFound().build();
        } catch (IllegalStateException e) {
            log.warn("권한 없음: {}", e.getMessage());
            return ResponseEntity.status(403).build();
        } catch (Exception e) {
            log.error("댓글 삭제 오류: {}", e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }
}
