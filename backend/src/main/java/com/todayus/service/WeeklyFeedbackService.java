package com.todayus.service;

import com.todayus.dto.WeeklyFeedbackDto;
import com.todayus.entity.Couple;
import com.todayus.entity.User;
import com.todayus.entity.WeeklyFeedback;
import com.todayus.repository.CoupleRepository;
import com.todayus.repository.UserRepository;
import com.todayus.repository.WeeklyFeedbackRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class WeeklyFeedbackService {

    private final WeeklyFeedbackRepository weeklyFeedbackRepository;
    private final UserRepository userRepository;
    private final CoupleRepository coupleRepository;
    private final AIAnalysisService aiAnalysisService;
    
    // 토요일 작성 가능 시간
    private static final LocalTime SATURDAY_START_TIME = LocalTime.of(7, 0); // 오전 7시
    private static final LocalTime SATURDAY_END_TIME = LocalTime.of(23, 59); // 오후 11시 59분

    /**
     * 현재 시간이 피드백 작성 가능한 시간인지 확인
     */
    public WeeklyFeedbackDto.WeeklyAvailabilityResponse checkAvailability(String userEmail) {
        User user = findUserByEmail(userEmail);
        LocalDateTime now = LocalDateTime.now();
        
        // 현재 토요일인지 확인
        if (now.getDayOfWeek() != DayOfWeek.SATURDAY) {
            LocalDateTime nextSaturday = getNextSaturday(now);
            return WeeklyFeedbackDto.WeeklyAvailabilityResponse.notAvailableTime(nextSaturday);
        }
        
        // 토요일이지만 시간이 범위에 없는 경우
        LocalTime currentTime = now.toLocalTime();
        if (currentTime.isBefore(SATURDAY_START_TIME) || currentTime.isAfter(SATURDAY_END_TIME)) {
            LocalDateTime nextAvailableTime = getNextAvailableTime(now);
            return WeeklyFeedbackDto.WeeklyAvailabilityResponse.notAvailableTime(nextAvailableTime);
        }
        
        // 현재 주에 이미 작성했는지 확인
        LocalDate currentWeekOf = getCurrentWeekOf();
        boolean alreadyWritten = weeklyFeedbackRepository.existsBySenderAndWeekOf(user, currentWeekOf);
        
        if (alreadyWritten) {
            return WeeklyFeedbackDto.WeeklyAvailabilityResponse.alreadyWritten(currentWeekOf);
        }
        
        return WeeklyFeedbackDto.WeeklyAvailabilityResponse.available(currentWeekOf);
    }

    /**
     * 서운함 피드백 작성
     */
    public WeeklyFeedbackDto.Response createFeedback(String userEmail, WeeklyFeedbackDto.CreateRequest request) {
        // 작성 가능 시간 재확인
        WeeklyFeedbackDto.WeeklyAvailabilityResponse availability = checkAvailability(userEmail);
        if (!availability.isCanWrite()) {
            throw new IllegalStateException(availability.getMessage());
        }

        User sender = findUserByEmail(userEmail);
        Couple couple = findCoupleByUser(sender);
        User receiver = getPartner(couple, sender);
        LocalDate weekOf = getCurrentWeekOf();

        // 피드백 엔티티 생성
        WeeklyFeedback feedback = WeeklyFeedback.builder()
                .sender(sender)
                .receiver(receiver)
                .couple(couple)
                .weekOf(weekOf)
                .originalMessage(request.getMessage())
                .status(WeeklyFeedback.FeedbackStatus.PENDING)
                .isRead(false)
                .build();

        WeeklyFeedback savedFeedback = weeklyFeedbackRepository.save(feedback);
        
        log.info("새로운 주간 피드백 작성됨 - 발신자: {}, 수신자: {}, 주차: {}", 
                sender.getEmail(), receiver.getEmail(), weekOf);

        // 비동기로 AI 처리 시작
        processAIRefinement(savedFeedback.getId());

        return WeeklyFeedbackDto.Response.from(savedFeedback);
    }

    /**
     * 받은 피드백 목록 조회 (읽지 않은 것만)
     */
    @Transactional(readOnly = true)
    public List<WeeklyFeedbackDto.ListResponse> getUnreadFeedbacks(String userEmail) {
        User receiver = findUserByEmail(userEmail);
        List<WeeklyFeedback> feedbacks = weeklyFeedbackRepository
                .findByReceiverAndIsReadFalseOrderByCreatedAtDesc(receiver);

        return feedbacks.stream()
                .filter(f -> f.getStatus() == WeeklyFeedback.FeedbackStatus.DELIVERED 
                          || f.getStatus() == WeeklyFeedback.FeedbackStatus.PROCESSED)
                .map(f -> WeeklyFeedbackDto.ListResponse.from(f, true))
                .collect(Collectors.toList());
    }

    /**
     * 피드백 히스토리 조회 (페이지네이션)
     */
    @Transactional(readOnly = true)
    public Page<WeeklyFeedbackDto.ListResponse> getFeedbackHistory(String userEmail, int page, int size) {
        User user = findUserByEmail(userEmail);
        Couple couple = findCoupleByUser(user);
        
        Pageable pageable = PageRequest.of(page, size);
        Page<WeeklyFeedback> feedbacks = weeklyFeedbackRepository.findByCoupleOrderByCreatedAtDesc(couple, pageable);

        return feedbacks.map(f -> {
            // 현재 사용자가 받은 피드백인지 확인
            boolean isReceived = f.getReceiver().equals(user);
            return WeeklyFeedbackDto.ListResponse.from(f, isReceived);
        });
    }

    /**
     * 특정 피드백 조회 및 읽음 처리
     */
    public WeeklyFeedbackDto.Response getFeedback(String userEmail, Long feedbackId) {
        User user = findUserByEmail(userEmail);
        WeeklyFeedback feedback = weeklyFeedbackRepository.findById(feedbackId)
                .orElseThrow(() -> new IllegalArgumentException("피드백을 찾을 수 없습니다."));

        // 권한 확인 (발신자 또는 수신자만 조회 가능)
        if (!feedback.getSender().equals(user) && !feedback.getReceiver().equals(user)) {
            throw new IllegalStateException("해당 피드백을 조회할 권한이 없습니다.");
        }

        // 수신자가 조회하는 경우 읽음 처리
        if (feedback.getReceiver().equals(user) && !feedback.getIsRead()) {
            feedback.markAsRead();
            weeklyFeedbackRepository.save(feedback);
            log.info("피드백 읽음 처리 - ID: {}, 수신자: {}", feedbackId, user.getEmail());
        }

        return WeeklyFeedbackDto.Response.from(feedback);
    }

    /**
     * AI 순화 처리 (비동기)
     */
    private void processAIRefinement(Long feedbackId) {
        // 별도 스레드에서 처리
        new Thread(() -> {
            try {
                WeeklyFeedback feedback = weeklyFeedbackRepository.findById(feedbackId)
                        .orElseThrow(() -> new IllegalArgumentException("피드백을 찾을 수 없습니다."));

                // 상태를 처리 중으로 변경
                feedback.setStatus(WeeklyFeedback.FeedbackStatus.PROCESSING);
                weeklyFeedbackRepository.save(feedback);

                log.info("AI 피드백 순화 시작 - ID: {}", feedbackId);

                // AI 서비스를 통해 메시지 순화
                String refinedMessage = aiAnalysisService.refineWeeklyFeedback(
                        feedback.getOriginalMessage(),
                        feedback.getSender().getNickname(),
                        feedback.getReceiver().getNickname()
                );

                // 순화 완료 처리
                feedback.markAsProcessed(refinedMessage);
                feedback.markAsDelivered(); // 바로 전달 상태로 변경
                weeklyFeedbackRepository.save(feedback);

                log.info("AI 피드백 순화 완료 - ID: {}", feedbackId);

            } catch (Exception e) {
                log.error("AI 피드백 순화 처리 중 오류 발생 - ID: {}, 오류: {}", feedbackId, e.getMessage(), e);
                
                // 오류 발생시 원본 메시지로 전달
                try {
                    WeeklyFeedback feedback = weeklyFeedbackRepository.findById(feedbackId).orElse(null);
                    if (feedback != null) {
                        feedback.markAsProcessed(feedback.getOriginalMessage());
                        feedback.markAsDelivered();
                        weeklyFeedbackRepository.save(feedback);
                    }
                } catch (Exception ex) {
                    log.error("피드백 오류 복구 중 추가 오류 발생 - ID: {}", feedbackId, ex);
                }
            }
        }).start();
    }

    /**
     * 현재 주의 토요일 날짜 계산
     */
    private LocalDate getCurrentWeekOf() {
        LocalDate now = LocalDate.now();
        int daysUntilSaturday = DayOfWeek.SATURDAY.getValue() - now.getDayOfWeek().getValue();
        if (daysUntilSaturday < 0) {
            daysUntilSaturday += 7; // 다음 주 토요일
        }
        return now.plusDays(daysUntilSaturday);
    }

    /**
     * 다음 토요일 오전 7시 계산
     */
    private LocalDateTime getNextSaturday(LocalDateTime current) {
        LocalDate currentDate = current.toLocalDate();
        int daysUntilSaturday = DayOfWeek.SATURDAY.getValue() - currentDate.getDayOfWeek().getValue();
        if (daysUntilSaturday <= 0) {
            daysUntilSaturday += 7;
        }
        return currentDate.plusDays(daysUntilSaturday).atTime(SATURDAY_START_TIME);
    }

    /**
     * 다음 작성 가능 시간 계산
     */
    private LocalDateTime getNextAvailableTime(LocalDateTime current) {
        if (current.getDayOfWeek() == DayOfWeek.SATURDAY) {
            // 토요일이지만 시간이 지났다면 다음 주 토요일
            if (current.toLocalTime().isAfter(SATURDAY_END_TIME)) {
                return current.toLocalDate().plusDays(7).atTime(SATURDAY_START_TIME);
            } else {
                // 토요일이지만 시간이 아직 안됐다면 오늘 7시
                return current.toLocalDate().atTime(SATURDAY_START_TIME);
            }
        } else {
            // 토요일이 아니라면 다음 토요일
            return getNextSaturday(current);
        }
    }

    // Helper methods
    private User findUserByEmail(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
    }

    private Couple findCoupleByUser(User user) {
        return coupleRepository.findByUser1OrUser2(user)
                .orElseThrow(() -> new IllegalStateException("커플 연결이 되어 있지 않습니다."));
    }

    private User getPartner(Couple couple, User user) {
        return couple.getPartner(user);
    }
}