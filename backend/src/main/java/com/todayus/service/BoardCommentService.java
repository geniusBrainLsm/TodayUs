package com.todayus.service;

import com.todayus.dto.BoardCommentDto;
import com.todayus.entity.Board;
import com.todayus.entity.BoardComment;
import com.todayus.entity.User;
import com.todayus.repository.BoardCommentRepository;
import com.todayus.repository.BoardRepository;
import com.todayus.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class BoardCommentService {

    private final BoardCommentRepository commentRepository;
    private final BoardRepository boardRepository;
    private final UserRepository userRepository;

    /**
     * 댓글 작성
     */
    @Transactional
    public BoardCommentDto.Response createComment(String userEmail, Long boardId, BoardCommentDto.CreateRequest request) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalStateException("사용자를 찾을 수 없습니다."));

        Board board = boardRepository.findByIdAndStatus(boardId, Board.BoardStatus.ACTIVE)
                .orElseThrow(() -> new IllegalArgumentException("게시글을 찾을 수 없습니다."));

        BoardComment comment = BoardComment.builder()
                .board(board)
                .author(user)
                .content(request.getContent())
                .status(BoardComment.CommentStatus.ACTIVE)
                .build();

        BoardComment saved = commentRepository.save(comment);
        log.info("댓글 작성 완료: id={}, boardId={}, author={}", saved.getId(), boardId, userEmail);

        return BoardCommentDto.Response.from(saved);
    }

    /**
     * 게시글의 댓글 목록 조회
     */
    @Transactional(readOnly = true)
    public List<BoardCommentDto.Response> getComments(Long boardId) {
        List<BoardComment> comments = commentRepository.findByBoardIdAndActiveOrderByCreatedAtAsc(boardId);
        return comments.stream()
                .map(BoardCommentDto.Response::from)
                .collect(Collectors.toList());
    }

    /**
     * 댓글 수정
     */
    @Transactional
    public BoardCommentDto.Response updateComment(String userEmail, Long commentId, BoardCommentDto.UpdateRequest request) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalStateException("사용자를 찾을 수 없습니다."));

        BoardComment comment = commentRepository.findById(commentId)
                .orElseThrow(() -> new IllegalArgumentException("댓글을 찾을 수 없습니다."));

        if (!comment.canEdit(user)) {
            throw new IllegalStateException("댓글 수정 권한이 없습니다.");
        }

        comment.setContent(request.getContent());
        BoardComment updated = commentRepository.save(comment);
        log.info("댓글 수정 완료: id={}, user={}", commentId, userEmail);

        return BoardCommentDto.Response.from(updated);
    }

    /**
     * 댓글 삭제
     */
    @Transactional
    public void deleteComment(String userEmail, Long commentId) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalStateException("사용자를 찾을 수 없습니다."));

        BoardComment comment = commentRepository.findById(commentId)
                .orElseThrow(() -> new IllegalArgumentException("댓글을 찾을 수 없습니다."));

        if (!comment.canDelete(user)) {
            throw new IllegalStateException("댓글 삭제 권한이 없습니다.");
        }

        comment.delete();
        commentRepository.save(comment);
        log.info("댓글 삭제 완료: id={}, user={}", commentId, userEmail);
    }

    /**
     * 게시글의 댓글 개수 조회
     */
    @Transactional(readOnly = true)
    public Long getCommentCount(Long boardId) {
        return commentRepository.countByBoardIdAndActive(boardId);
    }
}
