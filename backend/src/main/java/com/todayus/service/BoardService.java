package com.todayus.service;

import com.todayus.dto.BoardDto;
import com.todayus.entity.Board;
import com.todayus.entity.User;
import com.todayus.repository.BoardCommentRepository;
import com.todayus.repository.BoardRepository;
import com.todayus.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class BoardService {

    private final BoardRepository boardRepository;
    private final BoardCommentRepository commentRepository;
    private final UserRepository userRepository;

    /**
     * 게시글 생성
     */
    @Transactional
    public BoardDto.Response createBoard(String userEmail, BoardDto.CreateRequest request) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalStateException("사용자를 찾을 수 없습니다."));

        // 공지사항과 FAQ는 관리자만 작성 가능
        if ((request.getType() == Board.BoardType.NOTICE || request.getType() == Board.BoardType.FAQ)
                && user.getRole() != User.Role.ADMIN) {
            throw new IllegalStateException("공지사항과 FAQ는 관리자만 작성할 수 있습니다.");
        }

        Board board = Board.builder()
                .author(user)
                .title(request.getTitle())
                .content(request.getContent())
                .type(request.getType())
                .pinned(false)
                .viewCount(0)
                .status(Board.BoardStatus.ACTIVE)
                .build();

        Board saved = boardRepository.save(board);
        log.info("게시글 생성 완료: id={}, type={}, author={}", saved.getId(), saved.getType(), userEmail);

        return BoardDto.Response.from(saved);
    }

    /**
     * 게시글 목록 조회
     */
    @Transactional(readOnly = true)
    public Page<BoardDto.ListResponse> getBoards(int page, int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<Board> boards = boardRepository.findAllActive(pageable);
        return boards.map(BoardDto.ListResponse::from);
    }

    /**
     * 타입별 게시글 목록 조회
     */
    @Transactional(readOnly = true)
    public Page<BoardDto.ListResponse> getBoardsByType(Board.BoardType type, int page, int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<Board> boards = boardRepository.findByTypeAndActive(type, pageable);
        return boards.map(BoardDto.ListResponse::from);
    }

    /**
     * 게시글 상세 조회 (조회수 증가)
     */
    @Transactional
    public BoardDto.Response getBoard(Long boardId) {
        Board board = boardRepository.findByIdAndStatus(boardId, Board.BoardStatus.ACTIVE)
                .orElseThrow(() -> new IllegalArgumentException("게시글을 찾을 수 없습니다."));

        board.incrementViewCount();
        boardRepository.save(board);

        BoardDto.Response response = BoardDto.Response.from(board);
        response.setCommentCount(commentRepository.countByBoardIdAndActive(boardId));
        return response;
    }

    /**
     * 게시글 수정
     */
    @Transactional
    public BoardDto.Response updateBoard(String userEmail, Long boardId, BoardDto.UpdateRequest request) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalStateException("사용자를 찾을 수 없습니다."));

        Board board = boardRepository.findById(boardId)
                .orElseThrow(() -> new IllegalArgumentException("게시글을 찾을 수 없습니다."));

        if (!board.canEdit(user)) {
            throw new IllegalStateException("게시글 수정 권한이 없습니다.");
        }

        board.setTitle(request.getTitle());
        board.setContent(request.getContent());

        Board updated = boardRepository.save(board);
        log.info("게시글 수정 완료: id={}, user={}", boardId, userEmail);

        return BoardDto.Response.from(updated);
    }

    /**
     * 게시글 삭제
     */
    @Transactional
    public void deleteBoard(String userEmail, Long boardId) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalStateException("사용자를 찾을 수 없습니다."));

        Board board = boardRepository.findById(boardId)
                .orElseThrow(() -> new IllegalArgumentException("게시글을 찾을 수 없습니다."));

        if (!board.canDelete(user)) {
            throw new IllegalStateException("게시글 삭제 권한이 없습니다.");
        }

        board.delete();
        boardRepository.save(board);
        log.info("게시글 삭제 완료: id={}, user={}", boardId, userEmail);
    }

    /**
     * 내가 작성한 게시글 조회
     */
    @Transactional(readOnly = true)
    public Page<BoardDto.ListResponse> getMyBoards(String userEmail, int page, int size) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalStateException("사용자를 찾을 수 없습니다."));

        Pageable pageable = PageRequest.of(page, size);
        Page<Board> boards = boardRepository.findByAuthorId(user.getId(), pageable);
        return boards.map(BoardDto.ListResponse::from);
    }

    /**
     * 게시글 검색
     */
    @Transactional(readOnly = true)
    public Page<BoardDto.ListResponse> searchBoards(String keyword, int page, int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<Board> boards = boardRepository.searchByKeyword(keyword, pageable);
        return boards.map(BoardDto.ListResponse::from);
    }

    /**
     * 고정된 공지사항 조회
     */
    @Transactional(readOnly = true)
    public List<BoardDto.ListResponse> getPinnedNotices() {
        List<Board> boards = boardRepository.findPinnedNotices();
        return boards.stream()
                .map(BoardDto.ListResponse::from)
                .collect(Collectors.toList());
    }

    // === 관리자 전용 메서드 ===

    /**
     * 관리자: 게시글 고정/해제
     */
    @Transactional
    public BoardDto.Response togglePin(String userEmail, Long boardId) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalStateException("사용자를 찾을 수 없습니다."));

        if (user.getRole() != User.Role.ADMIN) {
            throw new IllegalStateException("관리자만 게시글을 고정할 수 있습니다.");
        }

        Board board = boardRepository.findById(boardId)
                .orElseThrow(() -> new IllegalArgumentException("게시글을 찾을 수 없습니다."));

        if (board.getPinned()) {
            board.unpin();
        } else {
            board.pin();
        }

        Board updated = boardRepository.save(board);
        log.info("게시글 고정 상태 변경: id={}, pinned={}", boardId, updated.getPinned());

        return BoardDto.Response.from(updated);
    }

    /**
     * 관리자: 게시글 상태 변경
     */
    @Transactional
    public BoardDto.Response updateBoardStatus(String userEmail, Long boardId, BoardDto.AdminUpdateRequest request) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalStateException("사용자를 찾을 수 없습니다."));

        if (user.getRole() != User.Role.ADMIN) {
            throw new IllegalStateException("관리자만 게시글 상태를 변경할 수 있습니다.");
        }

        Board board = boardRepository.findById(boardId)
                .orElseThrow(() -> new IllegalArgumentException("게시글을 찾을 수 없습니다."));

        if (request.getTitle() != null) {
            board.setTitle(request.getTitle());
        }
        if (request.getContent() != null) {
            board.setContent(request.getContent());
        }
        if (request.getPinned() != null) {
            board.setPinned(request.getPinned());
        }
        if (request.getStatus() != null) {
            board.setStatus(request.getStatus());
        }

        Board updated = boardRepository.save(board);
        log.info("관리자 게시글 수정 완료: id={}", boardId);

        return BoardDto.Response.from(updated);
    }

    /**
     * 관리자: 모든 게시글 조회
     */
    @Transactional(readOnly = true)
    public Page<BoardDto.Response> getAllBoardsForAdmin(String userEmail, int page, int size) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalStateException("사용자를 찾을 수 없습니다."));

        if (user.getRole() != User.Role.ADMIN) {
            throw new IllegalStateException("관리자만 모든 게시글을 조회할 수 있습니다.");
        }

        Pageable pageable = PageRequest.of(page, size);
        Page<Board> boards = boardRepository.findAllForAdmin(pageable);
        return boards.map(BoardDto.Response::from);
    }

    /**
     * 관리자: 게시글에 답변 등록
     */
    @Transactional
    public BoardDto.Response replyToBoard(String userEmail, Long boardId, BoardDto.AdminReplyRequest request) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalStateException("사용자를 찾을 수 없습니다."));

        if (user.getRole() != User.Role.ADMIN) {
            throw new IllegalStateException("관리자만 답변을 등록할 수 있습니다.");
        }

        Board board = boardRepository.findById(boardId)
                .orElseThrow(() -> new IllegalArgumentException("게시글을 찾을 수 없습니다."));

        board.setAdminReply(request.getReply());
        board.setAdminReplier(user);
        board.setAdminRepliedAt(java.time.LocalDateTime.now());

        Board updated = boardRepository.save(board);
        log.info("관리자 답변 등록 완료: boardId={}, admin={}", boardId, userEmail);

        return BoardDto.Response.from(updated);
    }
}
