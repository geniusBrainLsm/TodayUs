package com.todayus.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.theokanning.openai.completion.chat.ChatCompletionChoice;
import com.theokanning.openai.completion.chat.ChatCompletionRequest;
import com.theokanning.openai.completion.chat.ChatMessage;
import com.theokanning.openai.completion.chat.ChatMessageRole;
import com.theokanning.openai.service.OpenAiService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;
import com.todayus.entity.Diary;

@Slf4j
@Service
@RequiredArgsConstructor
public class AIAnalysisService {

    private final OpenAiService openAiService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public EmotionAnalysisResult analyzeEmotion(String title, String content) {
        try {
            String prompt = createEmotionAnalysisPrompt(title, content);
            
            ChatCompletionRequest chatRequest = ChatCompletionRequest.builder()
                    .model("gpt-4")
                    .messages(List.of(
                            new ChatMessage(ChatMessageRole.SYSTEM.value(), getSystemPrompt()),
                            new ChatMessage(ChatMessageRole.USER.value(), prompt)
                    ))
                    .maxTokens(500)
                    .temperature(0.3)
                    .build();

            List<ChatCompletionChoice> choices = openAiService.createChatCompletion(chatRequest).getChoices();
            
            if (choices.isEmpty()) {
                log.warn("No response from OpenAI");
                return createFallbackResult();
            }

            String response = choices.get(0).getMessage().getContent();
            log.info("OpenAI Response: {}", response);
            
            return parseEmotionAnalysisResult(response);
            
        } catch (Exception e) {
            log.error("Error analyzing emotion with OpenAI: {}", e.getMessage(), e);
            return createFallbackResult();
        }
    }

    public String generateAIComment(String title, String content, String detectedEmotion) {
        try {
            String prompt = createCommentGenerationPrompt(title, content, detectedEmotion);
            
            ChatCompletionRequest chatRequest = ChatCompletionRequest.builder()
                    .model("gpt-4")
                    .messages(List.of(
                            new ChatMessage(ChatMessageRole.SYSTEM.value(), getCommentSystemPrompt()),
                            new ChatMessage(ChatMessageRole.USER.value(), prompt)
                    ))
                    .maxTokens(300)
                    .temperature(0.7)
                    .build();

            List<ChatCompletionChoice> choices = openAiService.createChatCompletion(chatRequest).getChoices();
            
            if (choices.isEmpty()) {
                log.warn("No comment response from OpenAI");
                return "오늘도 소중한 일기를 작성해주셔서 감사해요! 💕";
            }

            return choices.get(0).getMessage().getContent().trim();
            
        } catch (Exception e) {
            log.error("Error generating AI comment: {}", e.getMessage(), e);
            return "오늘도 소중한 일기를 작성해주셔서 감사해요! 💕";
        }
    }

    private String getSystemPrompt() {
        return """
                당신은 커플 일기 앱의 감정 분석 AI입니다. 
                사용자의 일기를 읽고 감정을 분석하여 적절한 이모지와 간단한 감정 표현을 제공해주세요.
                
                응답은 반드시 다음 JSON 형식으로 해주세요:
                {
                    "emotion": "감정을 나타내는 이모지 (😊, 🥰, 😌, 😔, 😠, 😰, 🤔, 😴 중 하나)",
                    "description": "감정에 대한 한국어 설명 (예: 행복해요, 사랑스러워요, 평온해요, 우울해요, 화나요, 불안해요, 복잡해요, 피곤해요)"
                }
                
                일기의 전반적인 감정 상태를 파악하여 가장 적절한 하나의 감정을 선택해주세요.
                """;
    }

    private String getCommentSystemPrompt() {
        return """
                당신은 커플 일기 앱의 따뜻하고 공감적인 AI 친구입니다.
                사용자의 일기에 대해 따뜻하고 격려적인 댓글을 작성해주세요.
                
                조건:
                - 50-80자 정도의 간결한 댓글
                - 감정에 공감하고 위로하는 톤
                - 커플 관계를 응원하는 내용
                - 자연스러운 한국어 사용
                - 이모지 1-2개 포함
                - 상황에 맞는 적절한 조언이나 격려
                """;
    }

    private String createEmotionAnalysisPrompt(String title, String content) {
        return String.format("""
                다음 일기의 감정을 분석해주세요:
                
                제목: %s
                내용: %s
                
                이 일기의 전반적인 감정 상태를 파악하여 적절한 이모지와 설명을 JSON 형식으로 제공해주세요.
                """, title, content);
    }

    private String createCommentGenerationPrompt(String title, String content, String detectedEmotion) {
        return String.format("""
                다음 일기에 대해 따뜻한 AI 댓글을 작성해주세요:
                
                제목: %s
                내용: %s
                감지된 감정: %s
                
                이 일기를 쓴 사용자에게 공감과 격려를 담은 댓글을 작성해주세요.
                """, title, content, detectedEmotion);
    }

    private EmotionAnalysisResult parseEmotionAnalysisResult(String response) {
        try {
            // JSON 응답에서 ```json 부분 제거
            String jsonResponse = response;
            if (response.contains("```json")) {
                jsonResponse = response.substring(response.indexOf("```json") + 7);
                if (jsonResponse.contains("```")) {
                    jsonResponse = jsonResponse.substring(0, jsonResponse.indexOf("```"));
                }
            }
            
            JsonNode jsonNode = objectMapper.readTree(jsonResponse.trim());
            
            String emotion = jsonNode.path("emotion").asText();
            String description = jsonNode.path("description").asText();
            
            // 유효한 이모지인지 확인
            if (!isValidEmotion(emotion)) {
                log.warn("Invalid emotion detected: {}, using fallback", emotion);
                return createFallbackResult();
            }
            
            return new EmotionAnalysisResult(emotion, description);
            
        } catch (Exception e) {
            log.error("Error parsing emotion analysis result: {}", e.getMessage(), e);
            return createFallbackResult();
        }
    }

    private boolean isValidEmotion(String emotion) {
        return List.of("😊", "🥰", "😌", "😔", "😠", "😰", "🤔", "😴").contains(emotion);
    }

    private EmotionAnalysisResult createFallbackResult() {
        return new EmotionAnalysisResult("😊", "행복해요");
    }

    public static class EmotionAnalysisResult {
        private final String emotion;
        private final String description;

        public EmotionAnalysisResult(String emotion, String description) {
            this.emotion = emotion;
            this.description = description;
        }

        public String getEmotion() { return emotion; }
        public String getDescription() { return description; }
    }

    /**
     * 주간 감정 요약을 생성
     */
    public String generateWeeklyEmotionSummary(List<Diary> weeklyDiaries) {
        try {
            if (weeklyDiaries.isEmpty()) {
                return "이번 주에는 작성된 일기가 없어요.\n감정을 기록해보시는 건 어떨까요? 🌟";
            }

            // 이번 주 일기들의 감정과 내용을 분석할 텍스트로 준비
            String diariesText = weeklyDiaries.stream()
                    .map(diary -> String.format("[%s] %s (%s): %s", 
                            diary.getDiaryDate(),
                            diary.getUser().getNickname(),
                            diary.getMoodEmoji() != null ? diary.getMoodEmoji() : "😊",
                            diary.getContent().length() > 80 
                                ? diary.getContent().substring(0, 80) + "..." 
                                : diary.getContent()))
                    .collect(Collectors.joining("\n"));

            String prompt = createWeeklyEmotionSummaryPrompt(diariesText);
            
            ChatCompletionRequest chatRequest = ChatCompletionRequest.builder()
                    .model("gpt-4")
                    .messages(List.of(
                            new ChatMessage(ChatMessageRole.SYSTEM.value(), getWeeklyEmotionSummarySystemPrompt()),
                            new ChatMessage(ChatMessageRole.USER.value(), prompt)
                    ))
                    .maxTokens(150)
                    .temperature(0.7)
                    .build();

            List<ChatCompletionChoice> choices = openAiService.createChatCompletion(chatRequest).getChoices();
            
            if (choices.isEmpty()) {
                return "이번 주의 감정들을 정리하고 있어요.\n소중한 마음들이 담긴 한 주였네요 💝";
            }

            return choices.get(0).getMessage().getContent().trim();

        } catch (Exception e) {
            log.error("Error generating weekly emotion summary: {}", e.getMessage(), e);
            return "이번 주의 감정들을 정리하고 있어요.\n소중한 마음들이 담긴 한 주였네요 💝";
        }
    }

    /**
     * 커플의 최근 일기들을 바탕으로 3줄 요약을 생성
     */
    public String generateCoupleSummary(List<Diary> recentDiaries) {
        try {
            if (recentDiaries.isEmpty()) {
                return "아직 작성된 일기가 없어요.\n오늘부터 함께 소중한 순간들을\n기록해보세요 💕";
            }

            // 최근 일기들의 내용을 요약할 텍스트로 준비
            String diariesText = recentDiaries.stream()
                    .limit(10) // 최근 10개까지만
                    .map(diary -> String.format("[%s의 일기] %s: %s", 
                            diary.getUser().getNickname(),
                            diary.getTitle(), 
                            diary.getContent().length() > 100 
                                ? diary.getContent().substring(0, 100) + "..." 
                                : diary.getContent()))
                    .collect(Collectors.joining("\n\n"));

            String prompt = createCoupleSummaryPrompt(diariesText);
            
            ChatCompletionRequest chatRequest = ChatCompletionRequest.builder()
                    .model("gpt-4")
                    .messages(List.of(
                            new ChatMessage(ChatMessageRole.SYSTEM.value(), getCoupleSummarySystemPrompt()),
                            new ChatMessage(ChatMessageRole.USER.value(), prompt)
                    ))
                    .maxTokens(200)
                    .temperature(0.7)
                    .build();

            List<ChatCompletionChoice> choices = openAiService.createChatCompletion(chatRequest).getChoices();
            
            if (choices.isEmpty()) {
                log.warn("No response from OpenAI for couple summary");
                return createFallbackCoupleSummary();
            }

            String response = choices.get(0).getMessage().getContent().trim();
            log.info("OpenAI Couple Summary Response: {}", response);
            
            return response;
            
        } catch (Exception e) {
            log.error("Error generating couple summary: {}", e.getMessage(), e);
            return createFallbackCoupleSummary();
        }
    }

    private String createWeeklyEmotionSummaryPrompt(String diariesText) {
        return String.format("""
                다음은 지난 주 작성된 커플의 일기들입니다:
                
                %s
                
                이 일기들을 바탕으로 지난 주의 감정 흐름과 변화를 분석하여 요약해주세요.
                감정의 패턴, 긍정적인 변화, 또는 주목할 만한 감정적 성장이 있다면 따뜻하게 표현해주세요.
                """, diariesText);
    }

    private String createCoupleSummaryPrompt(String diariesText) {
        return String.format("""
                다음은 커플이 최근에 작성한 일기들입니다:
                
                %s
                
                이 일기들을 바탕으로 커플의 최근 상황과 감정을 따뜻하고 공감적인 톤으로 3줄 이내로 요약해주세요.
                각 줄은 25자 이내로 작성하고, 커플의 사랑과 일상을 아름답게 표현해주세요.
                """, diariesText);
    }

    private String getWeeklyEmotionSummarySystemPrompt() {
        return """
                당신은 커플 일기 앱의 감정 분석 전문 AI입니다.
                지난 주의 일기들을 바탕으로 감정의 흐름과 변화를 요약하는 역할을 합니다.
                
                요구사항:
                1. 2-3줄로 작성
                2. 각 줄은 30자 이내
                3. 감정의 전체적인 흐름 파악
                4. 긍정적인 변화나 성장 포인트 강조
                5. 따뜻하고 격려하는 톤
                6. 이모지 1-2개 포함
                7. 개행문자로 줄 구분
                """;
    }

    private String getCoupleSummarySystemPrompt() {
        return """
                당신은 커플 일기 앱의 따뜻한 AI 도우미입니다.
                커플의 일기를 읽고 그들의 사랑과 일상을 아름답게 요약하는 역할을 합니다.
                
                요구사항:
                1. 정확히 3줄로 작성
                2. 각 줄은 25자 이내
                3. 따뜻하고 공감적인 톤
                4. 커플의 감정과 상황을 포착
                5. 긍정적이고 응원하는 메시지
                6. 개행문자로 줄 구분
                """;
    }

    private String createFallbackCoupleSummary() {
        return "서로를 향한 마음이\n일기 속에 따뜻하게\n담겨있는 소중한 시간 💕";
    }
    
    /**
     * 커플 메시지를 순화해서 처리
     */
    public String processMessageForCouple(String originalMessage, String senderNickname, String receiverNickname) {
        try {
            String prompt = createMessageProcessingPrompt(originalMessage, senderNickname, receiverNickname);
            
            ChatCompletionRequest chatRequest = ChatCompletionRequest.builder()
                    .model("gpt-4")
                    .messages(List.of(
                            new ChatMessage(ChatMessageRole.SYSTEM.value(), getMessageProcessingSystemPrompt()),
                            new ChatMessage(ChatMessageRole.USER.value(), prompt)
                    ))
                    .maxTokens(300)
                    .temperature(0.7)
                    .build();

            List<ChatCompletionChoice> choices = openAiService.createChatCompletion(chatRequest).getChoices();
            
            if (choices.isEmpty()) {
                log.warn("No response from OpenAI for message processing");
                return originalMessage; // 실패 시 원본 반환
            }

            String processedMessage = choices.get(0).getMessage().getContent().trim();
            log.info("Message processed by AI: '{}' -> '{}'", originalMessage, processedMessage);
            
            return processedMessage;
            
        } catch (Exception e) {
            log.error("Error processing message with AI", e);
            return originalMessage; // 오류 시 원본 반환
        }
    }
    
    public String generateDiarySummary(String title, String content) {
        try {
            String prompt = createDiarySummaryPrompt(title, content);

            ChatCompletionRequest chatRequest = ChatCompletionRequest.builder()
                    .model("gpt-4")
                    .messages(List.of(
                            new ChatMessage(ChatMessageRole.SYSTEM.value(), getDiarySummarySystemPrompt()),
                            new ChatMessage(ChatMessageRole.USER.value(), prompt)
                    ))
                    .maxTokens(200)
                    .temperature(0.5)
                    .build();

            List<ChatCompletionChoice> choices = openAiService.createChatCompletion(chatRequest).getChoices();

            if (choices.isEmpty()) {
                log.warn("No response from OpenAI for diary summary");
                return createFallbackSummary(content);
            }

            String response = choices.get(0).getMessage().getContent().trim();

            if (response.startsWith("\"") && response.endsWith("\"") {
                response = response.substring(1, response.length() - 1);
            }

            return response;
        } catch (Exception e) {
            log.error("Error generating diary summary: {}", e.getMessage(), e);
            return createFallbackSummary(content);
        }
    }

    public String generateAiChatReply(String systemPrompt, String userPrompt) {
        try {
            ChatCompletionRequest chatRequest = ChatCompletionRequest.builder()
                    .model("gpt-4")
                    .messages(List.of(
                            new ChatMessage(ChatMessageRole.SYSTEM.value(), systemPrompt),
                            new ChatMessage(ChatMessageRole.USER.value(), userPrompt)
                    ))
                    .maxTokens(600)
                    .temperature(0.6)
                    .build();

            List<ChatCompletionChoice> choices = openAiService.createChatCompletion(chatRequest).getChoices();

            if (choices.isEmpty()) {
                log.warn("No response from OpenAI for AI chat");
                return "기록된 일기에서 관련 내용을 찾지 못했어요. 새로운 추억을 함께 만들어보는 건 어떨까요?";
            }

            return choices.get(0).getMessage().getContent().trim();
        } catch (Exception e) {
            log.error("Error generating AI chat reply: {}", e.getMessage(), e);
            return "지금은 답변을 만들어낼 수 없었어요. 잠시 후 다시 시도해 주세요.";
        }
    }

    private String getDiarySummarySystemPrompt() {
        return """
                당신은 연인들의 일기를 간단히 요약하는 AI 보조자입니다.
                입력으로 주어지는 일기의 제목과 내용을 보고 1-2문장으로 핵심만 부드럽게 정리해 주세요.
                날짜, 활동, 감정이 드러나면 좋습니다.
                120자 이내의 자연스러운 한국어 문장으로 답변하고, 추측하거나 꾸며내지 마세요.
                """;
    }

    private String createDiarySummaryPrompt(String title, String content) {
        return String.format("""
                다음 일기를 1-2문장으로 요약해 주세요.

                제목: %s
                내용: %s
                """, title, content);
    }

    private String createFallbackSummary(String content) {
        if (content == null || content.isBlank()) {
            return "기록된 내용이 없어 요약할 수 없었어요.";
        }
        String trimmed = content.trim();
        if (trimmed.length() <= 120) {
            return trimmed;
        }
        return trimmed.substring(0, 120) + "...";
    }

    private String createMessageProcessingPrompt(String originalMessage, String senderNickname, String receiverNickname) {
        return String.format("""
                다음은 %s님이 %s님에게 전하고 싶어하는 서운하거나 속상했던 마음입니다:
                
                원본 메시지: "%s"
                
                이 메시지를 다음 조건에 맞게 순화해서 전달해주세요:
                1. 상대방이 상처받지 않도록 부드럽고 따뜻한 표현 사용
                2. 비난보다는 자신의 감정을 표현하는 방식으로 변경
                3. 건설적이고 사랑스러운 톤으로 전환
                4. 150자 이내로 간결하게 정리
                5. 커플 간의 이해와 소통을 돕는 방향으로 작성
                
                순화된 메시지만 출력해주세요.
                """, senderNickname, receiverNickname, originalMessage);
    }
    
    private String getMessageProcessingSystemPrompt() {
        return """
                당신은 커플 간의 소통을 돕는 따뜻한 AI 중재자입니다.
                서운하거나 속상한 마음을 상대방이 이해하기 쉽고 상처받지 않게 전달하는 것이 목표입니다.
                
                원칙:
                1. 비난이나 공격적인 표현을 부드럽게 변환
                2. "나" 중심의 감정 표현으로 전환
                3. 상대방에 대한 사랑과 이해를 바탕으로 한 표현
                4. 건설적인 해결책이나 요청을 포함
                5. 따뜻하고 존중하는 톤 유지
                
                예시:
                - "왜 연락도 안 해?" → "연락이 오면 더 안심이 될 것 같아요 💕"
                - "너무 바빠서 시간도 안 내줘" → "함께 보내는 시간이 그리워요"
                """;
    }

    /**
     * 주간 피드백 메시지를 순화하여 전달
     */
    public String refineWeeklyFeedback(String originalMessage, String senderNickname, String receiverNickname) {
        try {
            String prompt = createFeedbackRefinementPrompt(originalMessage, senderNickname, receiverNickname);
            
            ChatCompletionRequest chatRequest = ChatCompletionRequest.builder()
                    .model("gpt-4")
                    .messages(List.of(
                            new ChatMessage(ChatMessageRole.SYSTEM.value(), getFeedbackRefinementSystemPrompt()),
                            new ChatMessage(ChatMessageRole.USER.value(), prompt)
                    ))
                    .maxTokens(400)
                    .temperature(0.5)
                    .build();

            List<ChatCompletionChoice> choices = openAiService.createChatCompletion(chatRequest).getChoices();
            
            if (choices.isEmpty()) {
                log.warn("No response from OpenAI for feedback refinement");
                return createFallbackRefinedMessage(originalMessage, senderNickname);
            }

            String response = choices.get(0).getMessage().getContent().trim();
            log.info("OpenAI Feedback Refinement Response: {}", response);
            
            return response;
            
        } catch (Exception e) {
            log.error("Error refining weekly feedback: {}", e.getMessage(), e);
            return createFallbackRefinedMessage(originalMessage, senderNickname);
        }
    }

    private String createFeedbackRefinementPrompt(String originalMessage, String senderNickname, String receiverNickname) {
        return String.format("""
                다음은 %s님이 %s님에게 전하고 싶은 서운했던 점입니다:
                
                "%s"
                
                이 메시지를 다음 조건에 맞춰 순화해서 전달해주세요:
                1. 비난이나 공격적인 표현을 제거하고 건설적으로 표현
                2. "I-메시지" 형태로 자신의 감정과 느낌 위주로 표현
                3. 상대방을 이해하려는 마음이 담기도록 작성
                4. 관계 개선을 위한 제안이나 바람 포함
                5. 따뜻하고 사랑스러운 톤으로 마무리
                6. 150-200자 내외로 작성
                """, senderNickname, receiverNickname, originalMessage);
    }

    private String getFeedbackRefinementSystemPrompt() {
        return """
                당신은 커플 관계 개선을 도와주는 전문 상담사 AI입니다.
                커플 간의 서운했던 점을 건설적이고 사랑스럽게 전달하는 역할을 합니다.
                
                핵심 원칙:
                1. 비난하지 않고 자신의 감정 표현하기 ("너는 ~했다" → "나는 ~하게 느꼈어")
                2. 구체적인 행동보다는 느낌과 감정에 집중
                3. 상대방의 의도를 긍정적으로 해석하려는 노력 보이기
                4. 관계 발전을 위한 건설적 제안 포함
                5. 사랑과 애정이 바탕에 깔린 표현 사용
                6. 상대방이 방어적이 되지 않도록 부드러운 톤 유지
                
                결과물은 서운함을 해결하고 관계를 더욱 돈독하게 만드는 데 도움이 되어야 합니다.
                """;
    }

    private String createFallbackRefinedMessage(String originalMessage, String senderNickname) {
        return String.format("""
                %s님이 마음속 깊이 간직했던 이야기가 있어요.
                
                서로를 더 깊이 이해하고 
                더욱 사랑하는 마음으로
                함께 성장해나가고 싶다고 해요 💕
                
                소중한 마음이 잘 전달되길 바라요.
                """, senderNickname);
    }

    /**
     * AI로 일일 메시지 생성
     */
    public String generateDailyMessage() {
        try {
            String prompt = """
                    오늘 하루를 시작하는 커플들에게 전할 따뜻하고 긍정적인 일일 메시지를 작성해주세요.

                    조건:
                    1. 20-30자 내외의 짧고 임팩트 있는 메시지
                    2. 사랑, 행복, 희망, 감사 등의 긍정적인 감정 포함
                    3. 커플이 함께 하는 일상의 소중함 강조
                    4. 이모지 1-2개 포함
                    5. 새로운 하루에 대한 기대감 표현

                    예시 스타일:
                    - "함께하는 모든 순간이 선물 같아요 🎁"
                    - "오늘도 서로에게 힘이 되어주세요 💪"
                    - "작은 행복들이 모여 큰 사랑이 되어요 ✨"
                    """;

            ChatCompletionRequest chatRequest = ChatCompletionRequest.builder()
                    .model("gpt-4")
                    .messages(List.of(
                            new ChatMessage(ChatMessageRole.SYSTEM.value(), getDailyMessageSystemPrompt()),
                            new ChatMessage(ChatMessageRole.USER.value(), prompt)
                    ))
                    .maxTokens(150)
                    .temperature(0.7)
                    .build();

            List<ChatCompletionChoice> choices = openAiService.createChatCompletion(chatRequest).getChoices();

            if (choices.isEmpty()) {
                log.warn("No response from OpenAI for daily message");
                return "새로운 하루, 새로운 추억을 만들어보세요! ✨";
            }

            String response = choices.get(0).getMessage().getContent().trim();

            // 따옴표 제거
            if (response.startsWith("\"") && response.endsWith("\"")) {
                response = response.substring(1, response.length() - 1);
            }

            log.info("AI Daily Message Generated: {}", response);

            return response;

        } catch (Exception e) {
            log.error("Error generating daily message: {}", e.getMessage(), e);
            return "새로운 하루, 새로운 추억을 만들어보세요! ✨";
        }
    }

    private String getDailyMessageSystemPrompt() {
        return """
                당신은 커플들에게 매일 따뜻한 메시지를 전하는 AI봇입니다.

                역할:
                - 커플들의 하루를 밝게 시작할 수 있는 긍정적인 메시지 작성
                - 사랑과 행복에 대한 인사이트 제공
                - 일상의 소중한 순간들에 대한 감사 표현

                톤앤매너:
                - 따뜻하고 친근한 말투
                - 진부하지 않으면서도 감동적인 표현
                - 실용적이면서도 로맨틱한 조언
                - 간결하면서도 의미 있는 메시지

                주의사항:
                - 너무 뻔하거나 진부한 표현 피하기
                - 특정 상황에 국한되지 않는 보편적인 메시지
                - 자연스럽고 진정성 있는 표현 사용
                """;
    }
}