package com.todayus.controller;

import com.todayus.dto.BoardDto;
import com.todayus.entity.Board;
import com.todayus.security.CustomOAuth2User;
import com.todayus.service.BoardService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api/boards")
@RequiredArgsConstructor
public class BoardController {

    private final BoardService boardService;

    /**
     * 게시글 생성
     */
    @PostMapping
    public ResponseEntity<BoardDto.Response> createBoard(
            @AuthenticationPrincipal CustomOAuth2User user,
            @Valid @RequestBody BoardDto.CreateRequest request) {

        log.info("게시글 생성 요청: user={}, type={}", user.getEmail(), request.getType());

        try {
            BoardDto.Response response = boardService.createBoard(user.getEmail(), request);
            return ResponseEntity.ok(response);
        } catch (IllegalStateException e) {
            log.warn("게시글 생성 실패: {}", e.getMessage());
            return ResponseEntity.badRequest().build();
        } catch (Exception e) {
            log.error("게시글 생성 오류: {}", e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * 게시글 목록 조회
     */
    @GetMapping
    public ResponseEntity<Page<BoardDto.ListResponse>> getBoards(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        log.info("게시글 목록 조회: page={}, size={}", page, size);

        try {
            Page<BoardDto.ListResponse> response = boardService.getBoards(page, size);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("게시글 목록 조회 오류: {}", e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * 타입별 게시글 목록 조회
     */
    @GetMapping("/type/{type}")
    public ResponseEntity<Page<BoardDto.ListResponse>> getBoardsByType(
            @PathVariable Board.BoardType type,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        log.info("타입별 게시글 조회: type={}, page={}, size={}", type, page, size);

        try {
            Page<BoardDto.ListResponse> response = boardService.getBoardsByType(type, page, size);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("타입별 게시글 조회 오류: {}", e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * 게시글 상세 조회
     */
    @GetMapping("/{boardId}")
    public ResponseEntity<BoardDto.Response> getBoard(@PathVariable Long boardId) {

        log.info("게시글 상세 조회: boardId={}", boardId);

        try {
            BoardDto.Response response = boardService.getBoard(boardId);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            log.warn("게시글 조회 실패: {}", e.getMessage());
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            log.error("게시글 조회 오류: {}", e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * 게시글 수정
     */
    @PutMapping("/{boardId}")
    public ResponseEntity<BoardDto.Response> updateBoard(
            @AuthenticationPrincipal CustomOAuth2User user,
            @PathVariable Long boardId,
            @Valid @RequestBody BoardDto.UpdateRequest request) {

        log.info("게시글 수정 요청: user={}, boardId={}", user.getEmail(), boardId);

        try {
            BoardDto.Response response = boardService.updateBoard(user.getEmail(), boardId, request);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            log.warn("게시글 수정 실패: {}", e.getMessage());
            return ResponseEntity.notFound().build();
        } catch (IllegalStateException e) {
            log.warn("게시글 수정 권한 없음: {}", e.getMessage());
            return ResponseEntity.status(403).build();
        } catch (Exception e) {
            log.error("게시글 수정 오류: {}", e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * 게시글 삭제
     */
    @DeleteMapping("/{boardId}")
    public ResponseEntity<Void> deleteBoard(
            @AuthenticationPrincipal CustomOAuth2User user,
            @PathVariable Long boardId) {

        log.info("게시글 삭제 요청: user={}, boardId={}", user.getEmail(), boardId);

        try {
            boardService.deleteBoard(user.getEmail(), boardId);
            return ResponseEntity.noContent().build();
        } catch (IllegalArgumentException e) {
            log.warn("게시글 삭제 실패: {}", e.getMessage());
            return ResponseEntity.notFound().build();
        } catch (IllegalStateException e) {
            log.warn("게시글 삭제 권한 없음: {}", e.getMessage());
            return ResponseEntity.status(403).build();
        } catch (Exception e) {
            log.error("게시글 삭제 오류: {}", e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * 내가 작성한 게시글 조회
     */
    @GetMapping("/my")
    public ResponseEntity<Page<BoardDto.ListResponse>> getMyBoards(
            @AuthenticationPrincipal CustomOAuth2User user,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        log.info("내 게시글 조회: user={}, page={}, size={}", user.getEmail(), page, size);

        try {
            Page<BoardDto.ListResponse> response = boardService.getMyBoards(user.getEmail(), page, size);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("내 게시글 조회 오류: {}", e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * 게시글 검색
     */
    @GetMapping("/search")
    public ResponseEntity<Page<BoardDto.ListResponse>> searchBoards(
            @RequestParam String keyword,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        log.info("게시글 검색: keyword={}, page={}, size={}", keyword, page, size);

        try {
            Page<BoardDto.ListResponse> response = boardService.searchBoards(keyword, page, size);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("게시글 검색 오류: {}", e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * 고정된 공지사항 조회
     */
    @GetMapping("/pinned")
    public ResponseEntity<List<BoardDto.ListResponse>> getPinnedNotices() {

        log.info("고정 공지사항 조회");

        try {
            List<BoardDto.ListResponse> response = boardService.getPinnedNotices();
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("고정 공지사항 조회 오류: {}", e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }
}
