package com.todayus.repository;

import com.todayus.entity.Board;
import com.todayus.entity.BoardComment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface BoardCommentRepository extends JpaRepository<BoardComment, Long> {

    @Query("SELECT c FROM BoardComment c WHERE c.board.id = :boardId AND c.status = 'ACTIVE' ORDER BY c.createdAt ASC")
    List<BoardComment> findByBoardIdAndActiveOrderByCreatedAtAsc(@Param("boardId") Long boardId);

    @Query("SELECT COUNT(c) FROM BoardComment c WHERE c.board.id = :boardId AND c.status = 'ACTIVE'")
    Long countByBoardIdAndActive(@Param("boardId") Long boardId);
}
