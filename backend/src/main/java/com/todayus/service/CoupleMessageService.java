package com.todayus.service;

import com.todayus.dto.CoupleMessageDto;
import com.todayus.entity.Couple;
import com.todayus.entity.CoupleMessage;
import com.todayus.entity.User;
import com.todayus.repository.CoupleMessageRepository;
import com.todayus.repository.CoupleRepository;
import com.todayus.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class CoupleMessageService {
    
    private final CoupleMessageRepository coupleMessageRepository;
    private final CoupleRepository coupleRepository;
    private final UserRepository userRepository;
    private final AIAnalysisService aiAnalysisService;
    
    private static final long MAX_WEEKLY_MESSAGES = 1; // 주당 1개 제한
    
    /**
     * 새로운 대신 전달하기 메시지 생성
     */
    public CoupleMessageDto.Response createMessage(String userEmail, CoupleMessageDto.CreateRequest request) {
        User sender = getUserByEmail(userEmail);
        Couple couple = findCoupleByUser(sender);
        User receiver = getPartner(couple, sender);
        
        // 주간 사용 제한 확인
        checkWeeklyUsageLimit(sender);
        
        // 메시지 생성 (PENDING 상태)
        CoupleMessage message = CoupleMessage.builder()
                .couple(couple)
                .sender(sender)
                .receiver(receiver)
                .originalMessage(request.getOriginalMessage())
                .aiProcessedMessage("") // AI 처리 전에는 빈 값
                .status(CoupleMessage.MessageStatus.PENDING)
                .build();
        
        CoupleMessage savedMessage = coupleMessageRepository.save(message);
        log.info("새로운 대신 전달하기 메시지 생성: {} -> {}", sender.getNickname(), receiver.getNickname());
        
        // 비동기로 AI 처리 시작
        processMessageWithAI(savedMessage.getId());
        
        return CoupleMessageDto.Response.from(savedMessage);
    }
    
    /**
     * 사용자 로그인 시 받을 메시지가 있는지 확인
     */
    @Transactional(readOnly = true)
    public Optional<CoupleMessageDto.PopupResponse> getMessageForPopup(String userEmail) {
        User receiver = getUserByEmail(userEmail);
        
        Optional<CoupleMessage> readyMessage = coupleMessageRepository.findReadyMessageForReceiver(receiver);
        
        if (readyMessage.isPresent()) {
            CoupleMessage message = readyMessage.get();
            log.info("사용자 {}에게 전달할 메시지 발견: {}", receiver.getNickname(), message.getId());
            return Optional.of(CoupleMessageDto.PopupResponse.from(message));
        }
        
        return Optional.empty();
    }
    
    /**
     * 메시지를 전달됨 상태로 변경 (팝업 표시됨)
     */
    public void markMessageAsDelivered(Long messageId, String userEmail) {
        User receiver = getUserByEmail(userEmail);
        
        CoupleMessage message = coupleMessageRepository.findById(messageId)
                .orElseThrow(() -> new IllegalArgumentException("메시지를 찾을 수 없습니다."));
        
        if (!message.getReceiver().equals(receiver)) {
            throw new IllegalArgumentException("해당 메시지의 수신자가 아닙니다.");
        }
        
        message.markAsDelivered();
        coupleMessageRepository.save(message);
        
        log.info("메시지 {} 전달 완료: {} -> {}", 
                messageId, message.getSender().getNickname(), receiver.getNickname());
    }
    
    /**
     * 메시지를 읽음 상태로 변경
     */
    public void markMessageAsRead(Long messageId, String userEmail) {
        User receiver = getUserByEmail(userEmail);
        
        CoupleMessage message = coupleMessageRepository.findById(messageId)
                .orElseThrow(() -> new IllegalArgumentException("메시지를 찾을 수 없습니다."));
        
        if (!message.getReceiver().equals(receiver)) {
            throw new IllegalArgumentException("해당 메시지의 수신자가 아닙니다.");
        }
        
        message.markAsRead();
        coupleMessageRepository.save(message);
        
        log.info("메시지 {} 읽음 완료: {}", messageId, receiver.getNickname());
    }
    
    /**
     * 사용자의 주간 사용량 조회 (테스트용: 24시간 기준)
     */
    @Transactional(readOnly = true)
    public CoupleMessageDto.WeeklyUsage getWeeklyUsage(String userEmail) {
        User user = getUserByEmail(userEmail);
        LocalDateTime dayStart = LocalDateTime.now().minusDays(1); // 테스트용으로 24시간으로 변경
        
        long usedCount = coupleMessageRepository.countBySenderAndCreatedAtAfter(user, dayStart);
        
        return CoupleMessageDto.WeeklyUsage.of(usedCount, MAX_WEEKLY_MESSAGES);
    }
    
    /**
     * 커플의 메시지 히스토리 조회
     */
    @Transactional(readOnly = true)
    public List<CoupleMessageDto.Response> getMessageHistory(String userEmail) {
        User user = getUserByEmail(userEmail);
        Couple couple = findCoupleByUser(user);
        
        List<CoupleMessage> messages = coupleMessageRepository.findByCoupleOrderByCreatedAtDesc(couple);
        
        return messages.stream()
                .map(CoupleMessageDto.Response::from)
                .collect(Collectors.toList());
    }
    
    /**
     * AI로 메시지 처리 (비동기)
     */
    @Async
    public void processMessageWithAI(Long messageId) {
        try {
            CoupleMessage message = coupleMessageRepository.findById(messageId)
                    .orElseThrow(() -> new IllegalArgumentException("메시지를 찾을 수 없습니다."));
            
            if (message.getStatus() != CoupleMessage.MessageStatus.PENDING) {
                log.warn("이미 처리된 메시지입니다: {}", messageId);
                return;
            }
            
            log.info("AI 메시지 처리 시작: {}", messageId);
            
            // 발신자와 수신자 정보 조회
            User sender = userRepository.findById(message.getSender().getId())
                    .orElseThrow(() -> new IllegalStateException("발신자를 찾을 수 없습니다."));
            User receiver = userRepository.findById(message.getReceiver().getId())
                    .orElseThrow(() -> new IllegalStateException("수신자를 찾을 수 없습니다."));
            
            // AI로 메시지 순화 처리
            String processedMessage = aiAnalysisService.processMessageForCouple(
                    message.getOriginalMessage(),
                    sender.getNickname(),
                    receiver.getNickname()
            );
            
            // 처리 완료 후 READY 상태로 변경
            message.setAiProcessedMessage(processedMessage);
            message.setStatus(CoupleMessage.MessageStatus.READY);
            coupleMessageRepository.save(message);
            
            log.info("AI 메시지 처리 완료: {} -> '{}'", messageId, processedMessage);
            
        } catch (Exception e) {
            log.error("AI 메시지 처리 실패: {}", messageId, e);
            // 실패한 경우에도 원본 메시지로 전달
            fallbackProcessMessage(messageId);
        }
    }
    
    /**
     * AI 처리 실패 시 원본 메시지로 처리
     */
    private void fallbackProcessMessage(Long messageId) {
        try {
            CoupleMessage message = coupleMessageRepository.findById(messageId)
                    .orElseThrow(() -> new IllegalArgumentException("메시지를 찾을 수 없습니다."));
            
            message.setAiProcessedMessage(message.getOriginalMessage());
            message.setStatus(CoupleMessage.MessageStatus.READY);
            coupleMessageRepository.save(message);
            
            log.info("메시지 폴백 처리 완료: {}", messageId);
            
        } catch (Exception e) {
            log.error("메시지 폴백 처리 실패: {}", messageId, e);
        }
    }
    
    /**
     * 주간 사용 제한 확인 (테스트용: 24시간 기준)
     */
    private void checkWeeklyUsageLimit(User sender) {
        LocalDateTime dayStart = LocalDateTime.now().minusDays(1); // 테스트용으로 24시간으로 변경
        long usedCount = coupleMessageRepository.countBySenderAndCreatedAtAfter(sender, dayStart);
        
        if (usedCount >= MAX_WEEKLY_MESSAGES) {
            throw new IllegalStateException("일간 사용 제한에 도달했습니다. 하루에 " + MAX_WEEKLY_MESSAGES + "개까지만 보낼 수 있습니다.");
        }
    }
    
    /**
     * 이메일로 사용자 조회
     */
    private User getUserByEmail(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> {
                    log.error("User not found with email: {}", email);
                    return new IllegalStateException("사용자를 찾을 수 없습니다.");
                });
    }
    
    /**
     * 사용자의 커플 조회
     */
    private Couple findCoupleByUser(User user) {
        Optional<Couple> coupleOpt = coupleRepository.findByUser1OrUser2(user);
        
        if (coupleOpt.isEmpty()) {
            log.warn("User {} is not in any couple relationship", user.getEmail());
            throw new IllegalStateException("커플 관계가 설정되지 않았습니다. 먼저 커플 연결을 완료해주세요.");
        }
        
        Couple couple = coupleOpt.get();
        if (couple.getStatus() != Couple.CoupleStatus.CONNECTED) {
            log.warn("Couple {} is not in CONNECTED status", couple.getId());
            throw new IllegalStateException("커플 관계가 연결되지 않은 상태입니다.");
        }
        
        return couple;
    }
    
    /**
     * 커플에서 상대방 사용자 조회
     */
    private User getPartner(Couple couple, User user) {
        return couple.getPartner(user);
    }
}