package com.todayus.repository;

import com.todayus.entity.Board;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface BoardRepository extends JpaRepository<Board, Long> {

    // 활성 상태의 게시글 조회 (고정 글 우선)
    @Query("SELECT b FROM Board b WHERE b.status = 'ACTIVE' ORDER BY b.pinned DESC, b.createdAt DESC")
    Page<Board> findAllActive(Pageable pageable);

    // 타입별 활성 상태 게시글 조회
    @Query("SELECT b FROM Board b WHERE b.type = :type AND b.status = 'ACTIVE' ORDER BY b.pinned DESC, b.createdAt DESC")
    Page<Board> findByTypeAndActive(@Param("type") Board.BoardType type, Pageable pageable);

    // ID로 활성 상태 게시글 조회
    Optional<Board> findByIdAndStatus(Long id, Board.BoardStatus status);

    // 사용자가 작성한 게시글 조회
    @Query("SELECT b FROM Board b WHERE b.author.id = :userId AND b.status = 'ACTIVE' ORDER BY b.createdAt DESC")
    Page<Board> findByAuthorId(@Param("userId") Long userId, Pageable pageable);

    // 고정된 공지사항 조회
    @Query("SELECT b FROM Board b WHERE b.type = 'NOTICE' AND b.pinned = true AND b.status = 'ACTIVE' ORDER BY b.createdAt DESC")
    List<Board> findPinnedNotices();

    // 제목이나 내용으로 검색
    @Query("SELECT b FROM Board b WHERE b.status = 'ACTIVE' AND (LOWER(b.title) LIKE LOWER(CONCAT('%', :keyword, '%')) OR LOWER(b.content) LIKE LOWER(CONCAT('%', :keyword, '%'))) ORDER BY b.pinned DESC, b.createdAt DESC")
    Page<Board> searchByKeyword(@Param("keyword") String keyword, Pageable pageable);

    // 관리자용: 모든 게시글 조회 (상태 무관)
    @Query("SELECT b FROM Board b ORDER BY b.pinned DESC, b.createdAt DESC")
    Page<Board> findAllForAdmin(Pageable pageable);
}
