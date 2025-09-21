package com.todayus.service;

import com.todayus.dto.AiChatDto;
import com.todayus.entity.Couple;
import com.todayus.entity.DiaryAiContext;
import com.todayus.entity.User;
import com.todayus.repository.CoupleRepository;
import com.todayus.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class AiChatService {

    private static final DateTimeFormatter DATE_FORMATTER =
            DateTimeFormatter.ofPattern("yyyy년 M월 d일", Locale.KOREAN);
    private static final int MAX_CONTEXT_ENTRIES = 80;
    private static final int MAX_MONTH_OVERVIEW = 6;
    private static final int SUMMARY_PER_MONTH = 2;
    private static final int MAX_RELEVANT_CONTEXT = 5;
    private static final int MAX_RECENT_HIGHLIGHTS = 2;
    private static final int MAX_CONTEXT_CHAR = 2800;

    private final UserRepository userRepository;
    private final CoupleRepository coupleRepository;
    private final DiaryContextService diaryContextService;
    private final AIAnalysisService aiAnalysisService;

    public AiChatDto.Response chat(String userEmail, AiChatDto.Request request) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalStateException("사용자를 찾을 수 없습니다."));

        Couple couple = coupleRepository.findByUser1OrUser2(user)
                .orElseThrow(() -> new IllegalStateException("커플 정보를 찾을 수 없습니다."));

        final String question = request.getMessage() == null ? "" : request.getMessage().trim();
        if (question.isEmpty()) {
            return AiChatDto.Response.builder()
                    .reply("어떤 이야기가 궁금하신가요? 말씀해 주시면 함께 떠올려 볼게요.")
                    .references(List.of())
                    .build();
        }

        List<DiaryAiContext> contexts = diaryContextService.getAllSummariesForCouple(couple);
        if (contexts.isEmpty()) {
            return AiChatDto.Response.builder()
                    .reply("아직 함께 기록한 일기가 없네요. 오늘부터 추억을 남겨보면 어떨까요?")
                    .references(List.of())
                    .build();
        }

        List<DiaryAiContext> sortedContexts = contexts.stream()
                .sorted(Comparator.comparing(DiaryAiContext::getDiaryDate))
                .collect(Collectors.toList());

        if (sortedContexts.size() > MAX_CONTEXT_ENTRIES) {
            sortedContexts = sortedContexts.subList(
                    sortedContexts.size() - MAX_CONTEXT_ENTRIES,
                    sortedContexts.size());
        }

        List<DiaryAiContext> relevantContexts = pickRelevantContexts(sortedContexts, question);
        List<DiaryAiContext> recentHighlights = pickRecentHighlights(sortedContexts);

        String monthlyOverview = buildMonthlyOverview(sortedContexts);
        String relevantSection = buildRelevantSection(relevantContexts);
        String recentSection = buildRecentSection(recentHighlights);
        String condensedContext = assembleContext(monthlyOverview, relevantSection, recentSection);
        String userPrompt = buildUserPrompt(condensedContext, question);
        String systemPrompt = buildSystemPrompt();

        String reply;
        try {
            reply = aiAnalysisService.generateAiChatReply(systemPrompt, userPrompt);
        } catch (Exception e) {
            log.error("AI chat generation failed for user {}: {}", user.getEmail(), e.getMessage(), e);
            reply = "지금은 잠시 고민 상자가 닫혀 있네요. 조금 뒤에 다시 이야기해 볼까요?";
        }

        LinkedHashSet<DiaryAiContext> referenceSet = new LinkedHashSet<>();
        referenceSet.addAll(relevantContexts);
        referenceSet.addAll(recentHighlights);

        List<AiChatDto.DiarySnippet> snippets = referenceSet.stream()
                .map(context -> AiChatDto.DiarySnippet.builder()
                        .diaryId(context.getDiary().getId())
                        .diaryDate(context.getDiaryDate())
                        .title(context.getTitle())
                        .moodEmoji(context.getMoodEmoji())
                        .summary(context.getSummary())
                        .build())
                .collect(Collectors.toList());

        return AiChatDto.Response.builder()
                .reply(reply)
                .references(snippets)
                .build();
    }

    private String assembleContext(String monthlyOverview, String relevantSection, String recentSection) {
        List<String> sections = new ArrayList<>();
        if (!monthlyOverview.isBlank()) {
            sections.add(monthlyOverview);
        }
        if (!relevantSection.isBlank()) {
            sections.add(relevantSection);
        }
        if (!recentSection.isBlank()) {
            sections.add(recentSection);
        }

        StringBuilder builder = new StringBuilder();
        for (String section : sections) {
            if (builder.length() + section.length() > MAX_CONTEXT_CHAR) {
                int remaining = MAX_CONTEXT_CHAR - builder.length();
                if (remaining > 80) {
                    builder.append(section, 0, remaining);
                }
                break;
            }
            builder.append(section);
        }
        return builder.toString();
    }

    private String buildMonthlyOverview(List<DiaryAiContext> contexts) {
        if (contexts.isEmpty()) {
            return "";
        }

        Map<YearMonth, List<DiaryAiContext>> grouped = new LinkedHashMap<>();
        for (DiaryAiContext context : contexts) {
            YearMonth key = YearMonth.from(context.getDiaryDate());
            grouped.computeIfAbsent(key, k -> new ArrayList<>()).add(context);
        }

        List<YearMonth> months = new ArrayList<>(grouped.keySet());
        if (months.size() > MAX_MONTH_OVERVIEW) {
            months = months.subList(months.size() - MAX_MONTH_OVERVIEW, months.size());
        }

        StringBuilder builder = new StringBuilder();
        builder.append("[최근 월별 요약]\n");
        for (YearMonth month : months) {
            builder.append("- ")
                    .append(month.getYear()).append("년 ")
                    .append(month.getMonthValue()).append("월")
                    .append("\n");

            grouped.get(month).stream()
                    .sorted(Comparator.comparing(DiaryAiContext::getDiaryDate))
                    .limit(SUMMARY_PER_MONTH)
                    .forEach(entry -> builder.append("  • ")
                            .append(entry.getDiaryDate().format(DATE_FORMATTER))
                            .append(" : ")
                            .append(truncate(entry.getSummary(), 140))
                            .append("\n"));
        }
        builder.append("\n");
        return builder.toString();
    }

    private String buildRelevantSection(List<DiaryAiContext> relevantContexts) {
        if (relevantContexts.isEmpty()) {
            return "";
        }
        StringBuilder builder = new StringBuilder();
        builder.append("[질문과 밀접한 기록]\n");
        for (DiaryAiContext context : relevantContexts) {
            builder.append("- ")
                    .append(context.getDiaryDate().format(DATE_FORMATTER))
                    .append(" | 제목: ")
                    .append(context.getTitle());
            if (context.getMoodEmoji() != null && !context.getMoodEmoji().isBlank()) {
                builder.append(" | 감정: ").append(context.getMoodEmoji());
            }
            builder.append("\n  요약: ")
                    .append(truncate(context.getSummary(), 160))
                    .append("\n\n");
        }
        return builder.toString();
    }

    private String buildRecentSection(List<DiaryAiContext> recentHighlights) {
        if (recentHighlights.isEmpty()) {
            return "";
        }
        StringBuilder builder = new StringBuilder();
        builder.append("[가장 최근의 기록]\n");
        for (DiaryAiContext context : recentHighlights) {
            builder.append("- ")
                    .append(context.getDiaryDate().format(DATE_FORMATTER))
                    .append(" | 제목: ")
                    .append(context.getTitle());
            if (context.getMoodEmoji() != null && !context.getMoodEmoji().isBlank()) {
                builder.append(" | 감정: ").append(context.getMoodEmoji());
            }
            builder.append("\n  요약: ")
                    .append(truncate(context.getSummary(), 140))
                    .append("\n\n");
        }
        return builder.toString();
    }

    private List<DiaryAiContext> pickRelevantContexts(List<DiaryAiContext> contexts, String question) {
        String normalizedQuestion = normalize(question);
        if (normalizedQuestion.isEmpty()) {
            return List.of();
        }
        Set<String> questionTokens = tokenSet(normalizedQuestion);
        if (questionTokens.isEmpty()) {
            return List.of();
        }

        return contexts.stream()
                .map(context -> new ScoredContext(context, scoreContext(context, questionTokens)))
                .filter(scored -> scored.score > 0)
                .sorted((a, b) -> Double.compare(b.score, a.score))
                .limit(MAX_RELEVANT_CONTEXT)
                .map(scored -> scored.context)
                .sorted(Comparator.comparing(DiaryAiContext::getDiaryDate))
                .collect(Collectors.toList());
    }

    private double scoreContext(DiaryAiContext context, Set<String> questionTokens) {
        StringBuilder builder = new StringBuilder();
        if (context.getTitle() != null) {
            builder.append(context.getTitle()).append(' ');
        }
        if (context.getSummary() != null) {
            builder.append(context.getSummary());
        }

        Set<String> contextTokens = tokenSet(normalize(builder.toString()));
        if (contextTokens.isEmpty()) {
            return 0.0;
        }

        long overlap = questionTokens.stream()
                .filter(token -> token.length() > 1)
                .filter(contextTokens::contains)
                .count();
        if (overlap == 0) {
            return 0.0;
        }

        double coverage = (double) overlap / questionTokens.size();
        long daysAgo = Math.abs(ChronoUnit.DAYS.between(context.getDiaryDate(), LocalDate.now()));
        double recencyWeight = 1.0 / (1.0 + daysAgo / 30.0);
        double summaryDensity = Math.min(1.0, contextTokens.size() / 150.0);
        return coverage * 0.7 + recencyWeight * 0.2 + summaryDensity * 0.1;
    }

    private List<DiaryAiContext> pickRecentHighlights(List<DiaryAiContext> contexts) {
        if (contexts.isEmpty()) {
            return List.of();
        }
        int fromIndex = Math.max(contexts.size() - MAX_RECENT_HIGHLIGHTS, 0);
        return new ArrayList<>(contexts.subList(fromIndex, contexts.size()));
    }

    private String buildUserPrompt(String contextSection, String question) {
        StringBuilder builder = new StringBuilder();
        builder.append(contextSection);
        builder.append("[사용자 질문]\n").append(question).append("\n\n");
        builder.append("위 정보에 근거해 답변하고, 확인되지 않은 부분은 추측하지 말고 솔직하게 모른다고 말해 주세요.\n");
        builder.append("상대의 마음을 공감하고 두 사람이 함께 실천할 수 있는 제안을 2~3가지 정도 제시해 주세요.");
        return builder.toString();
    }

    private String buildSystemPrompt() {
        return """
                당신은 커플 일기 AI 상담사입니다.
                - 제공된 일기 요약과 발췌로만 답변하세요.
                - 모르는 내용은 추측하지 말고 솔직하게 모른다고 말하세요.
                - 상대의 감정을 공감하고 관계를 응원하는 따뜻한 톤을 유지하세요.
                - 필요하다면 구체적인 실천 아이디어를 간단한 목록 형태로 제시하세요.
                """;
    }

    private String truncate(String text, int maxLength) {
        if (text == null) {
            return "";
        }
        String trimmed = text.trim();
        if (trimmed.length() <= maxLength) {
            return trimmed;
        }
        return trimmed.substring(0, maxLength - 1).trim() + "…";
    }

    private String normalize(String input) {
        if (input == null) {
            return "";
        }
        String normalized = input
                .toLowerCase(Locale.KOREAN)
                .replaceAll("[^a-z0-9가-힣\\s]", " ");
        return normalized.replaceAll("\\s+", " ").trim();
    }

    private Set<String> tokenSet(String text) {
        if (text.isEmpty()) {
            return Set.of();
        }
        return Arrays.stream(text.split(" "))
                .filter(token -> token.length() > 0)
                .collect(Collectors.toCollection(LinkedHashSet::new));
    }

    private static class ScoredContext {
        private final DiaryAiContext context;
        private final double score;

        private ScoredContext(DiaryAiContext context, double score) {
            this.context = context;
            this.score = score;
        }
    }
}