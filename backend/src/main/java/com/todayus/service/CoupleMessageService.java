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
import java.time.Duration;
import java.time.format.DateTimeFormatter;
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
    private final NotificationService notificationService;
    
    private static final Duration MESSAGE_COOLDOWN = Duration.ofHours(72);
    private static final long MAX_MESSAGES_PER_WINDOW = 1;
    private static final DateTimeFormatter COOLDOWN_DISPLAY_FORMAT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");
    
    /**
     * ?덈줈??????꾨떖?섍린 硫붿떆吏 ?앹꽦
     */
    public CoupleMessageDto.Response createMessage(String userEmail, CoupleMessageDto.CreateRequest request) {
        User sender = getUserByEmail(userEmail);
        Couple couple = findCoupleByUser(sender);
        User receiver = getPartner(couple, sender);
        
        // 二쇨컙 ?ъ슜 ?쒗븳 ?뺤씤
        checkUsageCooldown(sender);
        
        // 硫붿떆吏 ?앹꽦 (PENDING ?곹깭)
        CoupleMessage message = CoupleMessage.builder()
                .couple(couple)
                .sender(sender)
                .receiver(receiver)
                .originalMessage(request.getOriginalMessage())
                .aiProcessedMessage("") // AI 泥섎━ ?꾩뿉??鍮?媛?
                .status(CoupleMessage.MessageStatus.PENDING)
                .build();
        
        CoupleMessage savedMessage = coupleMessageRepository.save(message);
        log.info("?덈줈??????꾨떖?섍린 硫붿떆吏 ?앹꽦: {} -> {}", sender.getNickname(), receiver.getNickname());
        
        // 鍮꾨룞湲곕줈 AI 泥섎━ ?쒖옉
        processMessageWithAI(savedMessage.getId());
        
        return CoupleMessageDto.Response.from(savedMessage);
    }
    
    /**
     * ?ъ슜??濡쒓렇????諛쏆쓣 硫붿떆吏媛 ?덈뒗吏 ?뺤씤
     */
    @Transactional(readOnly = true)
    public Optional<CoupleMessageDto.PopupResponse> getMessageForPopup(String userEmail) {
        User receiver = getUserByEmail(userEmail);
        
        Optional<CoupleMessage> readyMessage = coupleMessageRepository.findReadyMessageForReceiver(receiver);
        
        if (readyMessage.isPresent()) {
            CoupleMessage message = readyMessage.get();
            log.info("?ъ슜??{}?먭쾶 ?꾨떖??硫붿떆吏 諛쒓껄: {}", receiver.getNickname(), message.getId());
            return Optional.of(CoupleMessageDto.PopupResponse.from(message));
        }
        
        return Optional.empty();
    }
    
    /**
     * 硫붿떆吏瑜??꾨떖???곹깭濡?蹂寃?(?앹뾽 ?쒖떆??
     */
    public void markMessageAsDelivered(Long messageId, String userEmail) {
        User receiver = getUserByEmail(userEmail);
        
        CoupleMessage message = coupleMessageRepository.findById(messageId)
                .orElseThrow(() -> new IllegalArgumentException("硫붿떆吏瑜?李얠쓣 ???놁뒿?덈떎."));
        
        if (!message.getReceiver().equals(receiver)) {
            throw new IllegalArgumentException("?대떦 硫붿떆吏???섏떊?먭? ?꾨떃?덈떎.");
        }
        
        message.markAsDelivered();
        coupleMessageRepository.save(message);
        
        log.info("硫붿떆吏 {} ?꾨떖 ?꾨즺: {} -> {}", 
                messageId, message.getSender().getNickname(), receiver.getNickname());
    }
    
    /**
     * 硫붿떆吏瑜??쎌쓬 ?곹깭濡?蹂寃?
     */
    public void markMessageAsRead(Long messageId, String userEmail) {
        User receiver = getUserByEmail(userEmail);
        
        CoupleMessage message = coupleMessageRepository.findById(messageId)
                .orElseThrow(() -> new IllegalArgumentException("硫붿떆吏瑜?李얠쓣 ???놁뒿?덈떎."));
        
        if (!message.getReceiver().equals(receiver)) {
            throw new IllegalArgumentException("?대떦 硫붿떆吏???섏떊?먭? ?꾨떃?덈떎.");
        }
        
        message.markAsRead();
        coupleMessageRepository.save(message);
        
        log.info("硫붿떆吏 {} ?쎌쓬 ?꾨즺: {}", messageId, receiver.getNickname());
    }
    
    /**
     * ?ъ슜?먯쓽 二쇨컙 ?ъ슜??議고쉶
     */
    @Transactional(readOnly = true)
    public CoupleMessageDto.WeeklyUsage getWeeklyUsage(String userEmail) {
        User user = getUserByEmail(userEmail);
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime cooldownStart = now.minus(MESSAGE_COOLDOWN);

        long usedCount = coupleMessageRepository.countBySenderAndCreatedAtAfter(user, cooldownStart);
        LocalDateTime nextAvailableAt = calculateNextAvailableAt(user).orElse(null);
        boolean canSend = nextAvailableAt == null;

        return CoupleMessageDto.WeeklyUsage.of(usedCount, MAX_MESSAGES_PER_WINDOW, canSend, nextAvailableAt);
    }
    
    /**
     * 而ㅽ뵆??硫붿떆吏 ?덉뒪?좊━ 議고쉶
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
     * AI濡?硫붿떆吏 泥섎━ (鍮꾨룞湲?
     */
    @Async
    public void processMessageWithAI(Long messageId) {
        try {
            CoupleMessage message = coupleMessageRepository.findById(messageId)
                    .orElseThrow(() -> new IllegalArgumentException("硫붿떆吏瑜?李얠쓣 ???놁뒿?덈떎."));
            
            if (message.getStatus() != CoupleMessage.MessageStatus.PENDING) {
                log.warn("?대? 泥섎━??硫붿떆吏?낅땲?? {}", messageId);
                return;
            }
            
            log.info("AI 硫붿떆吏 泥섎━ ?쒖옉: {}", messageId);
            
            // 諛쒖떊?먯? ?섏떊???뺣낫 議고쉶
            User sender = userRepository.findById(message.getSender().getId())
                    .orElseThrow(() -> new IllegalStateException("諛쒖떊?먮? 李얠쓣 ???놁뒿?덈떎."));
            User receiver = userRepository.findById(message.getReceiver().getId())
                    .orElseThrow(() -> new IllegalStateException("?섏떊?먮? 李얠쓣 ???놁뒿?덈떎."));
            
            // AI濡?硫붿떆吏 ?쒗솕 泥섎━
            String processedMessage = aiAnalysisService.processMessageForCouple(
                    message.getOriginalMessage(),
                    sender.getNickname(),
                    receiver.getNickname()
            );
            
            // 泥섎━ ?꾨즺 ??READY ?곹깭濡?蹂寃?
            message.setAiProcessedMessage(processedMessage);
            message.setStatus(CoupleMessage.MessageStatus.READY);
            coupleMessageRepository.save(message);

            // ?뚰듃?덉뿉寃??뚮┝ 諛쒖넚
            try {
                sendCoupleMessageNotification(sender, receiver, processedMessage);
            } catch (Exception e) {
                log.warn("????꾪빐二쇨린 ?뚮┝ 諛쒖넚 ?ㅽ뙣: {}", e.getMessage());
            }

            log.info("AI 硫붿떆吏 泥섎━ ?꾨즺: {} -> '{}'", messageId, processedMessage);
            
        } catch (Exception e) {
            log.error("AI 硫붿떆吏 泥섎━ ?ㅽ뙣: {}", messageId, e);
            // ?ㅽ뙣??寃쎌슦?먮룄 ?먮낯 硫붿떆吏濡??꾨떖
            fallbackProcessMessage(messageId);
        }
    }
    
    /**
     * AI 泥섎━ ?ㅽ뙣 ???먮낯 硫붿떆吏濡?泥섎━
     */
    private void fallbackProcessMessage(Long messageId) {
        try {
            CoupleMessage message = coupleMessageRepository.findById(messageId)
                    .orElseThrow(() -> new IllegalArgumentException("硫붿떆吏瑜?李얠쓣 ???놁뒿?덈떎."));
            
            message.setAiProcessedMessage(message.getOriginalMessage());
            message.setStatus(CoupleMessage.MessageStatus.READY);
            coupleMessageRepository.save(message);

            // ?대갚 泥섎━ ?쒖뿉???뚮┝ 諛쒖넚
            try {
                sendCoupleMessageNotification(message.getSender(), message.getReceiver(), message.getOriginalMessage());
            } catch (Exception e) {
                log.warn("?대갚 泥섎━ ?뚮┝ 諛쒖넚 ?ㅽ뙣: {}", e.getMessage());
            }

            log.info("硫붿떆吏 ?대갚 泥섎━ ?꾨즺: {}", messageId);
            
        } catch (Exception e) {
            log.error("硫붿떆吏 ?대갚 泥섎━ ?ㅽ뙣: {}", messageId, e);
        }
    }
    
    /**
     * 二쇨컙 ?ъ슜 ?쒗븳 ?뺤씤
     */
    private void checkUsageCooldown(User sender) {
        calculateNextAvailableAt(sender).ifPresent(nextAvailableAt -> {
            String formatted = nextAvailableAt.format(COOLDOWN_DISPLAY_FORMAT);
            throw new IllegalStateException("留덉쓬 ?꾪븯湲곕뒗 3?쇱뿉 ??踰덈쭔 蹂대궪 ???덉뼱?? " + formatted + " ?댄썑???ㅼ떆 ?쒕룄??二쇱꽭??");
        });
    }

    private Optional<LocalDateTime> calculateNextAvailableAt(User sender) {
        return coupleMessageRepository.findTopBySenderOrderByCreatedAtDesc(sender)
                .map(CoupleMessage::getCreatedAt)
                .map(createdAt -> createdAt.plus(MESSAGE_COOLDOWN))
                .filter(nextAvailable -> nextAvailable.isAfter(LocalDateTime.now()));
    }
    }
    
    /**
     * ?대찓?쇰줈 ?ъ슜??議고쉶
     */
    private User getUserByEmail(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> {
                    log.error("User not found with email: {}", email);
                    return new IllegalStateException("?ъ슜?먮? 李얠쓣 ???놁뒿?덈떎.");
                });
    }
    
    /**
     * ?ъ슜?먯쓽 而ㅽ뵆 議고쉶
     */
    private Couple findCoupleByUser(User user) {
        Optional<Couple> coupleOpt = coupleRepository.findByUser1OrUser2(user);
        
        if (coupleOpt.isEmpty()) {
            log.warn("User {} is not in any couple relationship", user.getEmail());
            throw new IllegalStateException("而ㅽ뵆 愿怨꾧? ?ㅼ젙?섏? ?딆븯?듬땲?? 癒쇱? 而ㅽ뵆 ?곌껐???꾨즺?댁＜?몄슂.");
        }
        
        Couple couple = coupleOpt.get();
        if (couple.getStatus() != Couple.CoupleStatus.CONNECTED) {
            log.warn("Couple {} is not in CONNECTED status", couple.getId());
            throw new IllegalStateException("而ㅽ뵆 愿怨꾧? ?곌껐?섏? ?딆? ?곹깭?낅땲??");
        }
        
        return couple;
    }
    
    /**
     * 而ㅽ뵆?먯꽌 ?곷?諛??ъ슜??議고쉶
     */
    private User getPartner(Couple couple, User user) {
        return couple.getPartner(user);
    }

    /**
     * ????꾪빐二쇨린 硫붿떆吏 ?뚮┝ 諛쒖넚
     */
    private void sendCoupleMessageNotification(User sender, User receiver, String messagePreview) {
        try {
            notificationService.sendCoupleMessageNotification(
                    sender.getId(),
                    sender.getNickname(),
                    messagePreview
            );

            log.info("????꾪빐二쇨린 ?뚮┝ 諛쒖넚 ?꾨즺: {} -> {}", sender.getNickname(), receiver.getNickname());

        } catch (Exception e) {
            log.error("????꾪빐二쇨린 ?뚮┝ 諛쒖넚 ?ㅽ뙣: {} -> {}, ?ㅻ쪟: {}",
                    sender.getNickname(), receiver.getNickname(), e.getMessage());
        }
    }
}

