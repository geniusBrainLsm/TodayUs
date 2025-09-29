package com.todayus.service;

import com.todayus.dto.DiaryDto;
import com.todayus.entity.Couple;
import com.todayus.entity.Diary;
import com.todayus.entity.DiaryComment;
import com.todayus.entity.User;
import com.todayus.repository.CoupleRepository;
import com.todayus.repository.DiaryCommentRepository;
import com.todayus.repository.DiaryRepository;
import com.todayus.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class DiaryService {
    
    private final DiaryRepository diaryRepository;
    private final DiaryCommentRepository commentRepository;
    private final UserRepository userRepository;
    private final CoupleRepository coupleRepository;
    private final AIAnalysisService aiAnalysisService;
    private final NotificationService notificationService;

    private final CoupleSummaryService coupleSummaryService;
    private final DiaryContextService diaryContextService;
    private final S3Service s3Service;
    
    public DiaryDto.Response createDiary(String userEmail, DiaryDto.CreateRequest request) {
        User user = findUserByEmail(userEmail);
        Couple couple = findCoupleByUser(user);
        
        // Check if user already has a diary for this date
        Optional<Diary> existingDiary = diaryRepository.findByUserAndDiaryDate(user, request.getDiaryDate());
        if (existingDiary.isPresent()) {
            throw new IllegalStateException("이미 해당 날짜에 작성된 일기가 있습니다.");
        }
        
        Diary diary = Diary.builder()
                .user(user)
                .couple(couple)
                .title(request.getTitle())
                .content(request.getContent())
                .diaryDate(request.getDiaryDate())
                .moodEmoji(request.getMoodEmoji())
                .imageUrl(request.getImageUrl())
                .status(Diary.DiaryStatus.PUBLISHED)
                .aiProcessed(false)
                .build();
        
        diary = diaryRepository.save(diary);

        // Trigger AI processing synchronously
        Long diaryId = diary.getId();
        processAiAnalysisSync(diaryId);

        // Send notification to partner
        try {
            sendDiaryCreatedNotification(user, diary);
        } catch (Exception e) {
            log.warn("Failed to send diary creation notification: {}", e.getMessage());
        }

        log.info("Diary created: {} by user: {}", diary.getId(), userEmail);

        return toDiaryResponse(diary, user);
    }
    
    @Transactional(readOnly = true)
    public Page<DiaryDto.ListResponse> getDiaries(String userEmail, int page, int size) {
        User user = findUserByEmail(userEmail);
        Couple couple = findCoupleByUser(user);
        
        Pageable pageable = PageRequest.of(page, size);
        Page<Diary> diaries = diaryRepository.findByCoupleOrderByDiaryDateDescCreatedAtDesc(couple, pageable);
        
        return diaries.map(diary -> {
            long commentCount = commentRepository.countByDiary(diary);
            User author = diary.getUser();
            return toDiaryListResponse(diary, author, commentCount);
        });
    }
    
    @Transactional(readOnly = true)
    public DiaryDto.Response getDiary(String userEmail, Long diaryId) {
        User user = findUserByEmail(userEmail);
        Diary diary = findDiaryById(diaryId);
        
        if (!diary.isAccessibleBy(user, diary.getCouple())) {
            throw new IllegalStateException("일기에 접근할 권한이 없습니다.");
        }
        
        List<DiaryComment> comments = commentRepository.findByDiaryOrderByCreatedAtAsc(diary);
        List<DiaryDto.CommentResponse> commentResponses = comments.stream()
                .map(comment -> DiaryDto.CommentResponse.from(comment, comment.getUser()))
                .collect(Collectors.toList());
        
        User author = diary.getUser();
        return toDiaryResponseWithComments(diary, author, commentResponses);
    }
    
    public DiaryDto.Response updateDiary(String userEmail, Long diaryId, DiaryDto.UpdateRequest request) {
        User user = findUserByEmail(userEmail);
        Diary diary = findDiaryById(diaryId);
        
        if (!diary.isOwnedBy(user.getId())) {
            throw new IllegalStateException("일기를 수정할 권한이 없습니다.");
        }
        
        if (request.getImageUrl() != null) {
            diary.updateContentWithImage(request.getTitle(), request.getContent(), request.getMoodEmoji(), request.getImageUrl());
        } else {
            diary.updateContent(request.getTitle(), request.getContent(), request.getMoodEmoji());
        }
        diary.setAiProcessed(false); // Reset AI processing flag when content changes
        
        diary = diaryRepository.save(diary);
        
        // Trigger AI processing synchronously for updated content
        processAiAnalysisSync(diary.getId());
        
        log.info("Diary updated: {} by user: {}", diary.getId(), userEmail);
        
        return toDiaryResponse(diary, user);
    }
    
    public void deleteDiary(String userEmail, Long diaryId) {
        User user = findUserByEmail(userEmail);
        Diary diary = findDiaryById(diaryId);
        
        if (!diary.isOwnedBy(user.getId())) {
            throw new IllegalStateException("일기를 삭제할 권한이 없습니다.");
        }
        
        diaryRepository.delete(diary);
        
        log.info("Diary deleted: {} by user: {}", diaryId, userEmail);
    }
    
    public DiaryDto.CommentResponse addComment(String userEmail, Long diaryId, DiaryDto.CommentRequest request) {
        log.info("=== Adding Comment to Diary ===");
        log.info("User email: {}, Diary ID: {}", userEmail, diaryId);
        log.info("Request content: {}", request != null ? request.getContent() : "null request");
        
        User user = findUserByEmail(userEmail);
        log.info("User found: ID={}, email={}", user.getId(), user.getEmail());
        
        Diary diary = findDiaryById(diaryId);
        log.info("Diary found: ID={}, title={}, author={}", 
                diary.getId(), diary.getTitle(), diary.getUser().getEmail());
        
        // Get user's couple for access check
        Couple userCouple = findCoupleByUser(user);
        log.info("User couple: {}", userCouple != null ? userCouple.getId() : "null");
        log.info("Diary couple: {}", diary.getCouple() != null ? diary.getCouple().getId() : "null");
        
        if (!diary.isAccessibleBy(user, userCouple)) {
            log.error("Access denied: user {} cannot access diary {}", userEmail, diaryId);
            log.error("User is diary owner: {}", diary.isOwnedBy(user));
            log.error("User couple matches diary couple: {}", 
                    userCouple != null && diary.getCouple() != null && userCouple.getId().equals(diary.getCouple().getId()));
            throw new IllegalStateException("일기에 접근할 권한이 없습니다.");
        }
        
        log.info("Access granted. Creating comment...");
        
        DiaryComment comment = DiaryComment.builder()
                .diary(diary)
                .user(user)
                .content(request.getContent())
                .type(DiaryComment.CommentType.USER)
                .build();
        
        log.info("Comment built: content={}, type={}", comment.getContent(), comment.getType());
        
        try {
            comment = commentRepository.save(comment);
            log.info("Comment saved successfully: ID={}", comment.getId());
        } catch (Exception e) {
            log.error("Failed to save comment: {}", e.getMessage(), e);
            throw e;
        }
        
        if (!user.getId().equals(diary.getUser().getId())) {
            try {
                String commenterName = (user.getNickname() != null && !user.getNickname().isBlank())
                        ? user.getNickname()
                        : user.getName();

                notificationService.sendDiaryCommentNotification(
                    user.getId(),
                    commenterName,
                    diary.getId(),
                    diary.getTitle(),
                    comment.getId(),
                    comment.getContent()
                );
            } catch (Exception e) {
                log.warn("Failed to send diary comment notification for diary {} by user {}: {}", diaryId, userEmail, e.getMessage());
            }
        }

        log.info("Comment added to diary: {} by user: {}", diaryId, userEmail);
        
        DiaryDto.CommentResponse response = DiaryDto.CommentResponse.from(comment, user);
        log.info("Response created: {}", response);
        
        return response;
    }
    
    @Transactional(readOnly = true)
    public List<DiaryDto.Response> getRecentDiaries(String userEmail, int limit) {
        User user = findUserByEmail(userEmail);
        Couple couple = findCoupleByUser(user);
        
        Pageable pageable = PageRequest.of(0, limit);
        List<Diary> recentDiaries = diaryRepository.findRecentByCoupleOrderByCreatedAtDesc(couple, pageable);
        
        return recentDiaries.stream()
                .map(diary -> toDiaryResponse(diary, diary.getUser()))
                .collect(Collectors.toList());
    }

    /**
     * 주간 감정 요약 생성
     */
    @Transactional(readOnly = true)
    public String generateWeeklyEmotionSummary(String userEmail) {
        try {
            User user = findUserByEmail(userEmail);
            Couple couple = findCoupleByUser(user);
            
            // 지난 7일간의 일기를 가져옴
            LocalDate endDate = LocalDate.now();
            LocalDate startDate = endDate.minusDays(7);
            List<Diary> weeklyDiaries = diaryRepository.findByCoupleAndDiaryDateBetweenOrderByDiaryDateDesc(
                couple, startDate, endDate);
            
            if (weeklyDiaries.isEmpty()) {
                return "이번 주에는 작성된 일기가 없어요.\n감정을 기록해보시는 건 어떨까요? 🌟";
            }
            
            return aiAnalysisService.generateWeeklyEmotionSummary(weeklyDiaries);
            
        } catch (Exception e) {
            log.error("Error generating weekly emotion summary for user {}: {}", userEmail, e.getMessage(), e);
            return "이번 주의 감정들을 정리하고 있어요.\n소중한 마음들이 담긴 한 주였네요 💝";
        }
    }

    /**
     * 커플의 오늘 일기 작성 상태 확인 및 요약 생성
     */
    @Transactional(readOnly = true)
    public Map<String, Object> getCoupleSummary(String userEmail) {
        try {
            User user = findUserByEmail(userEmail);
            Couple couple = findCoupleByUser(user);
            
            LocalDate today = LocalDate.now();
            
            // 커플의 오늘 일기 작성 상태 확인
            Optional<Diary> userTodayDiary = diaryRepository.findByUserAndDiaryDate(user, today);
            
            User partner = (couple.getUser1().equals(user)) ? couple.getUser2() : couple.getUser1();
            Optional<Diary> partnerTodayDiary = diaryRepository.findByUserAndDiaryDate(partner, today);
            
            Map<String, Object> result = new HashMap<>();
            result.put("partnerName", partner.getNickname());
            
            if (userTodayDiary.isPresent() && partnerTodayDiary.isPresent()) {
                // 양쪽 모두 작성함 - AI 요약 생성
                result.put("status", "BOTH_WRITTEN");
                
                String aiSummary = coupleSummaryService.getTodaysCoupleSummary(couple);
                result.put("summary", aiSummary);
                
            } else if (userTodayDiary.isPresent() && partnerTodayDiary.isEmpty()) {
                // 내가만 작성함
                result.put("status", "ONLY_USER_WRITTEN");
                result.put("summary", null);
                
            } else if (userTodayDiary.isEmpty() && partnerTodayDiary.isPresent()) {
                // 파트너만 작성함
                result.put("status", "ONLY_PARTNER_WRITTEN");
                result.put("summary", null);
                
            } else {
                // 둘 다 작성하지 않음
                result.put("status", "NEITHER_WRITTEN");
                result.put("summary", null);
            }
            
            return result;
            
        } catch (Exception e) {
            log.error("Error getting couple summary for user {}: {}", userEmail, e.getMessage(), e);
            Map<String, Object> errorResult = new HashMap<>();
            errorResult.put("status", "ERROR");
            errorResult.put("summary", "서로를 향한 마음이\n일기 속에 따뜻하게\n담겨있는 소중한 시간 💕");
            return errorResult;
        }
    }
    
    /**
     * 커플의 최근 일기들을 바탕으로 AI 3줄 요약 생성 (레거시)
     */
    @Transactional(readOnly = true)
    public String generateCoupleSummary(String userEmail) {
        try {
            User user = findUserByEmail(userEmail);
            Couple couple = findCoupleByUser(user);
            
            return coupleSummaryService.getTodaysCoupleSummary(couple);
            
        } catch (Exception e) {
            log.error("Error generating couple summary for user {}: {}", userEmail, e.getMessage(), e);
            return "서로를 향한 마음이\n일기 속에 따뜻하게\n담겨있는 소중한 시간 💕";
        }
    }
    
    @Transactional(readOnly = true)
    public List<DiaryDto.EmotionStats> getEmotionStats(String userEmail, LocalDate startDate, LocalDate endDate) {
        User user = findUserByEmail(userEmail);
        Couple couple = findCoupleByUser(user);

        List<Object[]> stats = diaryRepository.getEmotionStatsByDateRange(couple, startDate, endDate);
        long total = stats.stream().mapToLong(stat -> (Long) stat[1]).sum();

        return stats.stream()
                .map(stat -> DiaryDto.EmotionStats.of((String) stat[0], (Long) stat[1], total))
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public boolean hasTodayDiary(String userEmail) {
        User user = findUserByEmail(userEmail);
        LocalDate today = LocalDate.now();
        Optional<Diary> todayDiary = diaryRepository.findByUserAndDiaryDate(user, today);
        return todayDiary.isPresent();
    }
    
    // AI processing methods
    public void processAiAnalysis(Long diaryId) {
        processAiAnalysisSync(diaryId);
    }
    
    
    private void processAiAnalysisSync(Long diaryId) {
        try {
            log.info("🔍 Starting AI analysis for diary: {}", diaryId);

            Diary diary = diaryRepository.findById(diaryId)
                    .orElseThrow(() -> new IllegalStateException("일기를 찾을 수 없습니다."));

            log.info("📖 Found diary: title='{}', content length={}, aiProcessed={}",
                    diary.getTitle(), diary.getContent() != null ? diary.getContent().length() : 0, diary.getAiProcessed());

            if (diary.getAiProcessed()) {
                log.info("⚠️ Diary {} already processed by AI", diaryId);
                return;
            }

            log.info("🧠 Starting emotion analysis...");
            // 1. Analyze emotion
            AIAnalysisService.EmotionAnalysisResult emotionResult =
                    aiAnalysisService.analyzeEmotion(diary.getTitle(), diary.getContent());
            log.info("😊 Emotion analysis result: emotion='{}', description='{}'",
                    emotionResult.getEmotion(), emotionResult.getDescription());

            log.info("💬 Generating AI comment...");
            // 2. Generate AI comment
            String aiComment = aiAnalysisService.generateAIComment(
                    diary.getTitle(),
                    diary.getContent(),
                    emotionResult.getDescription()
            );
            log.info("💭 AI comment generated: '{}'", aiComment);
            
            // 3. Update diary with AI analysis results
            diary.setAiEmotion(emotionResult.getEmotion());
            diary.setAiComment(aiComment);
            diary.setAiProcessed(true);
            diaryRepository.save(diary);
            
            diaryContextService.upsertDiarySummary(diary);
            
            // 4. Create AI comment
            DiaryComment aiCommentEntity = DiaryComment.builder()
                    .diary(diary)
                    .user(null) // AI comment has no user
                    .content(aiComment)
                    .type(DiaryComment.CommentType.AI)
                    .build();
            commentRepository.save(aiCommentEntity);
            
            log.info("AI analysis completed for diary: {} with emotion: {}", 
                    diaryId, emotionResult.getEmotion());
            
        } catch (Exception e) {
            log.error("Error processing AI analysis for diary {}: {}", diaryId, e.getMessage(), e);
        }
    }

    /**
     * 일기 작성 시 파트너에게 알림 발송
     */
    private void sendDiaryCreatedNotification(User author, Diary diary) {
        try {
            String title = String.format("💕 %s님이 일기를 작성했어요", author.getNickname());
            String body = String.format("\"%s\" - 새로운 이야기가 궁금하지 않나요?",
                    diary.getTitle().length() > 30 ? diary.getTitle().substring(0, 30) + "..." : diary.getTitle());

            Map<String, String> data = new HashMap<>();
            data.put("type", "diary_created");
            data.put("action", "navigate_to_diary");
            data.put("diary_id", diary.getId().toString());
            data.put("author_name", author.getNickname());

            notificationService.sendNotificationToPartner(
                author.getId(),
                title,
                body,
                "diary_created",
                data
            );

            log.info("Diary creation notification sent for diary {} by user {}", diary.getId(), author.getEmail());

        } catch (Exception e) {
            log.error("Error sending diary creation notification for diary {} by user {}: {}",
                    diary.getId(), author.getEmail(), e.getMessage());
        }
    }

    private DiaryDto.Response toDiaryResponse(Diary diary, User author) {
        log.debug("📄 Creating detail response for diary {}: originalImageUrl={}", diary.getId(), diary.getImageUrl());
        DiaryDto.Response response = DiaryDto.Response.from(diary, author);
        String resolvedImageUrl = s3Service.resolveDiaryImageUrl(diary.getImageUrl());
        log.debug("📄 Resolved image URL for diary {}: {} -> {}", diary.getId(), diary.getImageUrl(), resolvedImageUrl);
        response.setImageUrl(resolvedImageUrl);
        return response;
    }

    private DiaryDto.Response toDiaryResponseWithComments(Diary diary, User author, List<DiaryDto.CommentResponse> comments) {
        DiaryDto.Response response = DiaryDto.Response.fromWithComments(diary, author, comments);
        response.setImageUrl(s3Service.resolveDiaryImageUrl(diary.getImageUrl()));
        return response;
    }

    private DiaryDto.ListResponse toDiaryListResponse(Diary diary, User author, long commentCount) {
        log.debug("📋 Creating list response for diary {}: originalImageUrl={}", diary.getId(), diary.getImageUrl());
        DiaryDto.ListResponse response = DiaryDto.ListResponse.from(diary, author, commentCount);
        String resolvedImageUrl = s3Service.resolveDiaryImageUrl(diary.getImageUrl());
        log.debug("📋 Resolved image URL for diary {}: {} -> {}", diary.getId(), diary.getImageUrl(), resolvedImageUrl);
        response.setImageUrl(resolvedImageUrl);
        return response;
    }

    private User findUserByEmail(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> {
                    log.error("User not found with email: {}", email);
                    return new IllegalStateException("사용자를 찾을 수 없습니다.");
                });
    }
    
    private Couple findCoupleByUser(User user) {
        Optional<Couple> coupleOpt = coupleRepository.findByUser1OrUser2(user);
        
        if (coupleOpt.isEmpty()) {
            log.warn("User {} is not in any couple relationship", user.getEmail());
            throw new IllegalStateException("커플 관계가 설정되지 않았습니다.");
        }
        
        Couple couple = coupleOpt.get();
        if (couple.getStatus() != Couple.CoupleStatus.CONNECTED) {
            log.warn("Couple {} is not in CONNECTED status", couple.getId());
            throw new IllegalStateException("커플 관계가 연결되지 않은 상태입니다.");
        }
        
        return couple;
    }
    
    private Diary findDiaryById(Long diaryId) {
        return diaryRepository.findById(diaryId)
                .orElseThrow(() -> {
                    log.error("Diary not found with id: {}", diaryId);
                    return new IllegalStateException("일기를 찾을 수 없습니다.");
                });
    }
}