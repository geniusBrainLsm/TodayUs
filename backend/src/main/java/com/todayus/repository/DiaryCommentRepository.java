package com.todayus.repository;

import com.todayus.entity.Diary;
import com.todayus.entity.DiaryComment;
import com.todayus.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface DiaryCommentRepository extends JpaRepository<DiaryComment, Long> {
    
    // Find comments by diary (entity-based)
    List<DiaryComment> findByDiaryOrderByCreatedAtAsc(Diary diary);
    
    // Find comments by user (entity-based)
    List<DiaryComment> findByUserOrderByCreatedAtDesc(User user);
    
    // Find AI comments by diary (entity-based)
    @Query("SELECT c FROM DiaryComment c WHERE c.diary = :diary AND c.type = 'AI' ORDER BY c.createdAt ASC")
    List<DiaryComment> findAiCommentsByDiary(@Param("diary") Diary diary);
    
    // Find user comments by diary (entity-based)
    @Query("SELECT c FROM DiaryComment c WHERE c.diary = :diary AND c.type = 'USER' ORDER BY c.createdAt ASC")
    List<DiaryComment> findUserCommentsByDiary(@Param("diary") Diary diary);
    
    // Count comments by diary (entity-based)
    long countByDiary(Diary diary);
    
    // ID-based methods for backward compatibility
    List<DiaryComment> findByDiaryIdOrderByCreatedAtAsc(Long diaryId);
    List<DiaryComment> findByUserIdOrderByCreatedAtDesc(Long userId);
    long countByDiaryId(Long diaryId);
    
    @Query("SELECT c FROM DiaryComment c WHERE c.diary.id = :diaryId AND c.type = 'AI' ORDER BY c.createdAt ASC")
    List<DiaryComment> findAiCommentsByDiaryId(@Param("diaryId") Long diaryId);
    
    @Query("SELECT c FROM DiaryComment c WHERE c.diary.id = :diaryId AND c.type = 'USER' ORDER BY c.createdAt ASC")
    List<DiaryComment> findUserCommentsByDiaryId(@Param("diaryId") Long diaryId);
    
    // Count AI comments
    @Query("SELECT COUNT(c) FROM DiaryComment c WHERE c.type = 'AI'")
    long countAiComments();
}