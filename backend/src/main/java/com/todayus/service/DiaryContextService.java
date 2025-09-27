package com.todayus.service;

import com.todayus.entity.Couple;
import com.todayus.entity.Diary;
import com.todayus.entity.DiaryAiContext;
import com.todayus.repository.DiaryAiContextRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class DiaryContextService {

    private final DiaryAiContextRepository diaryAiContextRepository;
    private final AIAnalysisService aiAnalysisService;

    public void upsertDiarySummary(Diary diary) {
        try {
            String summary = aiAnalysisService.generateDiarySummary(
                    diary.getTitle(),
                    diary.getContent()
            );

            DiaryAiContext context = diaryAiContextRepository.findByDiary(diary)
                    .orElseGet(() -> DiaryAiContext.builder()
                            .diary(diary)
                            .couple(diary.getCouple())
                            .build());

            context.setCouple(diary.getCouple());
            context.setDiaryDate(diary.getDiaryDate());
            context.setTitle(diary.getTitle());
            context.setMoodEmoji(diary.getMoodEmoji());
            context.setSummary(summary);

            diaryAiContextRepository.save(context);
        } catch (Exception e) {
            log.error("Failed to upsert diary AI context for diary {}: {}", diary.getId(), e.getMessage(), e);
        }
    }

    @Transactional(readOnly = true)
    public List<DiaryAiContext> getAllSummariesForCouple(Couple couple) {
        return diaryAiContextRepository.findByCoupleOrderByDiaryDateAsc(couple);
    }

    @Transactional(readOnly = true)
    public List<DiaryAiContext> getRecentSummariesForCouple(Couple couple, int limit) {
        List<DiaryAiContext> recent = diaryAiContextRepository.findTop100ByCoupleOrderByDiaryDateDesc(couple);
        if (recent.size() <= limit) {
            return recent;
        }
        return recent.subList(0, limit);
    }
}


