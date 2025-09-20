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
                    .reply("어떤 이야기가 궁금한지 말씀해 주면 함께 살펴볼게요!")
                    .references(List.of())
                    .build();
        }

        List<DiaryAiContext> contexts = diaryContextService.getAllSummariesForCouple(couple);
        if (contexts.isEmpty()) {
            return AiChatDto.Response.builder()
                    .reply("아직 함께 기록한 일기가 없어요. 오늘의 추억을 첫 페이지에 남겨볼까요?")
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
        String reply = aiAnalysisService.generateAiChatReply(systemPrompt, userPrompt);

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
        builder.append("다음은 커플이 지금까지 작성한 일기 요약 목록입니다. 이 정보를 참고해 질문에 답해주세요.

");

        for (DiaryAiContext context : contexts) {
            builder.append("- ")
                    .append(context.getDiaryDate().format(DATE_FORMATTER))
                    .append(" | 제목: ")
                    .append(context.getTitle());
            if (context.getMoodEmoji() != null && !context.getMoodEmoji().isBlank()) {
                builder.append(" | 감정: ").append(context.getMoodEmoji());
            }
            builder.append("
  요약: ")
                    .append(context.getSummary())
                    .append("

");
        }

        builder.append("질문: ").append(question).append("
");
        builder.append("위 일기에서 확인할 수 없는 내용은 추측하지 말고 솔직하게 모른다고 알려주세요.
");
        builder.append("답변은 다정하면서도 두 사람의 관계를 응원하는 톤으로 작성해주세요.");

        return builder.toString();
    }

    private String buildSystemPrompt() {
        return """
                당신은 서로 사랑하는 커플의 일기를 기반으로 추억을 상기시켜 주는 AI 파트너입니다.
                사용자 질문에 답할 때는 제공된 일기 요약에서 확인할 수 있는 정보만 활용하세요.
                모르는 내용은 사실대로 모른다고 말하고, 새로운 추억을 제안하는 식으로 긍정적으로 마무리해 주세요.
                두 사람 모두를 존중하는 따뜻한 말투를 유지하고, 어느 한쪽을 우열을 가리는 질문에는 균형 잡힌 답변을 하세요.
                """;
    }
}
