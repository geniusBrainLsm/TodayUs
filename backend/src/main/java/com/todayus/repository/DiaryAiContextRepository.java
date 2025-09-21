package com.todayus.repository;

import com.todayus.entity.Couple;
import com.todayus.entity.Diary;
import com.todayus.entity.DiaryAiContext;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface DiaryAiContextRepository extends JpaRepository<DiaryAiContext, Long> {

    Optional<DiaryAiContext> findByDiary(Diary diary);

    List<DiaryAiContext> findByCoupleOrderByDiaryDateAsc(Couple couple);

    List<DiaryAiContext> findTop100ByCoupleOrderByDiaryDateDesc(Couple couple);
}
