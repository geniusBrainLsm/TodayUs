from pathlib import Path

path = Path(r"main\\java\\com\\todayus\\service\\DiaryContextService.java")
text = path.read_text(encoding="utf-8")
marker = "    @Transactional(readOnly = true)\r\n    public List<DiaryAiContext> getRecentSummariesForCouple(Couple couple, int limit) {"
new_method = "    public List<DiaryAiContext> getOrCreateSummariesForCouple(Couple couple) {\r\n        List<DiaryAiContext> contexts = diaryAiContextRepository.findByCoupleOrderByDiaryDateAsc(couple);\r\n        List<Diary> diaries = diaryRepository.findByCoupleOrderByDiaryDateAsc(couple);\r\n\r\n        if (diaries.isEmpty()) {\r\n            return contexts;\r\n        }\r\n\r\n        Set<Long> existingDiaryIds = contexts.stream()\r\n                .map(context -> context.getDiary().getId())\r\n                .collect(Collectors.toSet());\r\n\r\n        boolean updated = false;\r\n        for (Diary diary : diaries) {\r\n            if (!existingDiaryIds.contains(diary.getId())) {\r\n                upsertDiarySummary(diary);\r\n                updated = true;\r\n            }\r\n        }\r\n\r\n        if (updated) {\r\n            return diaryAiContextRepository.findByCoupleOrderByDiaryDateAsc(couple);\r\n        }\r\n        return contexts;\r\n    }\r\n\r\n"
if marker not in text:
    raise SystemExit('marker not found')
if 'getOrCreateSummariesForCouple' not in text:
    text = text.replace(marker, new_method + marker)
    path.write_text(text, encoding='utf-8')
