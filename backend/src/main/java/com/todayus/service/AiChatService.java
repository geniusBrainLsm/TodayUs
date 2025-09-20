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

import java.time.format.DateTimeFormatter;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class AiChatService {

    private static final DateTimeFormatter DATE_FORMATTER =
            DateTimeFormatter.ofPattern("yyyy년 M월 d일", Locale.KOREAN);
    private static final int MAX_CONTEXT_ENTRIES = 80;

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
                    .reply("어떤 이야기가 궁금하신가요? 말씀해 주시면 함께 돌아볼게요.")
                    .references(List.of())
                    .build();
        }

        List<DiaryAiContext> contexts = diaryContextService.getAllSummariesForCouple(couple);
        if (contexts.isEmpty()) {
            return AiChatDto.Response.builder()
                    .reply("아직 함께 기록한 일기가 없네요. 오늘의 추억을 하나 남겨볼까요?")
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

        String userPrompt = buildUserPrompt(sortedContexts, question);
        String systemPrompt = buildSystemPrompt();

        String reply;
        try {
            reply = aiAnalysisService.generateAiChatReply(systemPrompt, userPrompt);
        } catch (Exception e) {
            log.error("AI chat generation failed for user {}: {}", user.getEmail(), e.getMessage(), e);
            reply = "지금은 잠시 대화를 이어가기 어려워요. 조금 뒤에 다시 시도해 주세요.";
        }

        List<AiChatDto.DiarySnippet> snippets = sortedContexts.stream()
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

    private String buildUserPrompt(List<DiaryAiContext> contexts, String question) {
        StringBuilder builder = new StringBuilder();
        builder.append("아래는 커플이 지금까지 작성한 일기 요약 목록입니다. 이 정보를 참고해 질문에 답해주세요.\n\n");

        for (DiaryAiContext context : contexts) {
            builder.append("- ")
                    .append(context.getDiaryDate().format(DATE_FORMATTER))
                    .append(" | 제목: ")
                    .append(context.getTitle());
            if (context.getMoodEmoji() != null && !context.getMoodEmoji().isBlank()) {
                builder.append(" | 감정: ").append(context.getMoodEmoji());
            }
            builder.append("\n  요약: ")
                    .append(context.getSummary())
                    .append("\n\n");
        }

        builder.append("질문: ").append(question).append("\n");
        builder.append("일기에 기록된 사실로 확인되지 않는 내용은 추측하지 말고 모른다고 말해주세요.\n");
        builder.append("두 사람이 서로를 응원할 수 있도록 따뜻한 어조로 답변해주세요.");

        return builder.toString();
    }

    private String buildSystemPrompt() {
        return """
                당신은 사랑하는 커플의 일기를 기반으로 추억을 되살려 주는 AI 챗봇입니다.
                사용자의 질문에 답할 때는 제공된 일기 요약에서 확인한 정보만 활용하세요.
                모르는 내용은 꾸미거나 추측하지 말고, 솔직하게 모른다고 말해도 괜찮습니다.
                추억을 소중히 여기는 따뜻한 말투로, 두 사람 모두를 존중하며 답변해주세요.
                """;
    }
}
