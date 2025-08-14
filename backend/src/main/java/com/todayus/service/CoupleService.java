package com.todayus.service;

import com.todayus.dto.CoupleDto;
import com.todayus.dto.InviteCodeDto;
import com.todayus.dto.UserDto;
import com.todayus.entity.Couple;
import com.todayus.entity.InviteCode;
import com.todayus.entity.User;
import com.todayus.repository.CoupleRepository;
import com.todayus.repository.InviteCodeRepository;
import com.todayus.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class CoupleService {
    
    private final CoupleRepository coupleRepository;
    private final InviteCodeRepository inviteCodeRepository;
    private final UserRepository userRepository;
    private final SecureRandom secureRandom = new SecureRandom();
    
    @Transactional
    public InviteCodeDto generateInviteCode(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
        
        // 이미 커플이 있는지 확인
        if (coupleRepository.existsByUserAndConnected(user)) {
            throw new IllegalStateException("이미 연결된 커플이 있습니다.");
        }
        
        // 기존 활성 초대 코드 만료
        inviteCodeRepository.expireActiveInvitesByInviter(user);
        
        // 중복 활성 코드 정리 (안전장치)
        cleanupDuplicateActiveCodes(user);
        
        // 새 초대 코드 생성
        String code = generateUniqueCode();
        InviteCode inviteCode = InviteCode.builder()
                .code(code)
                .inviter(user)
                .expiresAt(LocalDateTime.now().plusHours(24))
                .status(InviteCode.InviteStatus.ACTIVE)
                .build();
        
        InviteCode savedInviteCode = inviteCodeRepository.save(inviteCode);
        log.info("사용자 {}에 대한 초대 코드 {} 생성", userId, code);
        
        return InviteCodeDto.from(savedInviteCode);
    }
    
    @Transactional
    public CoupleDto connectWithInviteCode(Long userId, String code) {
        log.info("초대 코드로 연결 시작 - 사용자 ID: {}, 코드: {}", userId, code);
        
        User invitee = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
        
        log.info("초대받은 사용자 정보 - ID: {}, 이메일: {}, 닉네임: {}", 
                invitee.getId(), invitee.getEmail(), invitee.getNickname());
        
        // 이미 커플이 있는지 확인
        if (coupleRepository.existsByUserAndConnected(invitee)) {
            log.warn("이미 연결된 커플이 있는 사용자의 연결 시도 - 사용자 ID: {}", userId);
            throw new IllegalStateException("이미 연결된 커플이 있습니다.");
        }
        
        // 초대 코드 검증
        InviteCode inviteCode = inviteCodeRepository.findByCodeAndStatus(code, InviteCode.InviteStatus.ACTIVE)
                .orElseThrow(() -> {
                    log.warn("유효하지 않은 초대 코드 - 코드: {}", code);
                    return new IllegalArgumentException("유효하지 않은 초대 코드입니다.");
                });
        
        log.info("초대 코드 검증 성공 - ID: {}, 초대자: {}, 만료시간: {}", 
                inviteCode.getId(), inviteCode.getInviter().getEmail(), inviteCode.getExpiresAt());
        
        if (inviteCode.isExpired()) {
            log.warn("만료된 초대 코드 사용 시도 - 코드: {}, 만료시간: {}", code, inviteCode.getExpiresAt());
            inviteCode.markAsExpired();
            inviteCodeRepository.save(inviteCode);
            throw new IllegalArgumentException("만료된 초대 코드입니다.");
        }
        
        // 자기 자신의 코드인지 확인
        if (inviteCode.getInviter().equals(invitee)) {
            log.warn("자기 자신의 초대 코드 사용 시도 - 사용자 ID: {}", userId);
            throw new IllegalArgumentException("자신의 초대 코드로는 연결할 수 없습니다.");
        }
        
        User inviter = inviteCode.getInviter();
        log.info("초대자 정보 - ID: {}, 이메일: {}, 닉네임: {}", 
                inviter.getId(), inviter.getEmail(), inviter.getNickname());
        
        // 이미 커플 관계가 있는지 확인
        Optional<Couple> existingCouple = coupleRepository.findByUsers(inviter, invitee);
        if (existingCouple.isPresent()) {
            if (existingCouple.get().getStatus() == Couple.CoupleStatus.CONNECTED) {
                throw new IllegalStateException("이미 연결된 커플입니다.");
            }
            // 기존 관계가 있지만 끊어진 경우, 다시 연결
            Couple couple = existingCouple.get();
            couple.setStatus(Couple.CoupleStatus.CONNECTED);
            couple.setConnectedAt(LocalDateTime.now());
            coupleRepository.save(couple);
            
            inviteCode.markAsUsed(invitee);
            inviteCodeRepository.save(inviteCode);
            
            log.info("기존 커플 관계 재연결: {} - {}", inviter.getId(), invitee.getId());
            return CoupleDto.from(couple, UserDto.from(inviter));
        }
        
        // 새 커플 생성
        Couple couple = Couple.builder()
                .user1(inviter)
                .user2(invitee)
                .status(Couple.CoupleStatus.CONNECTED)
                .connectedAt(LocalDateTime.now())
                .build();
        
        Couple savedCouple = coupleRepository.save(couple);
        
        // 초대 코드 사용 처리
        inviteCode.markAsUsed(invitee);
        inviteCodeRepository.save(inviteCode);
        
        log.info("새 커플 연결: {} - {}", inviter.getId(), invitee.getId());
        return CoupleDto.from(savedCouple, UserDto.from(inviter));
    }
    
    public Optional<CoupleDto> getCoupleInfo(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
        return coupleRepository.findByUserAndStatus(user)
                .map(couple -> {
                    User partner = couple.getPartner(user);
                    return CoupleDto.from(couple, UserDto.from(partner));
                });
    }
    
    public Optional<InviteCodeDto> getActiveInviteCode(Long userId) {
        if (userId == null) {
            log.error("getActiveInviteCode: userId is null");
            throw new IllegalArgumentException("사용자 ID가 null입니다.");
        }
        
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
        
        // 중복 활성 초대 코드 정리 (안전장치)
        cleanupDuplicateActiveCodes(user);
        
        try {
            Optional<InviteCode> activeInvite = inviteCodeRepository.findActiveInviteByInviter(user);
            
            if (activeInvite.isPresent()) {
                InviteCode inviteCode = activeInvite.get();
                
                // 만료 체크 전에 필요한 필드들이 null이 아닌지 확인
                if (inviteCode.getCode() == null || inviteCode.getExpiresAt() == null) {
                    log.warn("초대 코드의 필수 필드가 null입니다 - ID: {}, code: {}, expiresAt: {}", 
                            inviteCode.getId(), inviteCode.getCode(), inviteCode.getExpiresAt());
                    return Optional.empty();
                }
                
                if (!inviteCode.isExpired()) {
                    return Optional.of(InviteCodeDto.from(inviteCode));
                } else {
                    log.info("만료된 초대 코드 발견 - 사용자: {}, 코드: {}", userId, inviteCode.getCode());
                    return Optional.empty();
                }
            }
            
            return Optional.empty();
            
        } catch (Exception e) {
            log.error("활성 초대 코드 조회 중 오류 발생 - 사용자: {}, 오류: {}", userId, e.getMessage(), e);
            throw e;
        }
    }
    
    @Transactional
    public void disconnectCouple(Long userId) {
        Couple couple = coupleRepository.findByUserIdAndStatus(userId)
                .orElseThrow(() -> new IllegalArgumentException("연결된 커플이 없습니다."));
        
        couple.setStatus(Couple.CoupleStatus.DISCONNECTED);
        coupleRepository.save(couple);
        
        // 해당 사용자의 활성 초대 코드 만료
        User user = userRepository.findById(userId).orElseThrow(()->new IllegalArgumentException("유저 없어요"));
        inviteCodeRepository.expireActiveInvitesByInviter(user);
        
        log.info("커플 연결 해제: 사용자 {}", userId);
    }
    
    @Transactional
    public void cancelActiveInvites(Long userId) {
        User user = userRepository.findById(userId).orElseThrow(()->new IllegalArgumentException("유저 없어요"));

        int canceledCount = inviteCodeRepository.expireActiveInvitesByInviter(user);
        log.info("사용자 {}의 활성 초대 코드 {} 개 취소", userId, canceledCount);
    }
    
    /**
     * 중복 활성 초대 코드 정리 (안전장치)
     * 하나의 사용자당 하나의 활성 초대 코드만 유지
     */
    @Transactional
    private void cleanupDuplicateActiveCodes(User user) {
        if (user == null) {
            log.warn("cleanupDuplicateActiveCodes: user is null");
            return;
        }
        
        try {
            List<InviteCode> activeCodes = inviteCodeRepository.findAllActiveInvitesByInviter(user);
            
            if (activeCodes == null) {
                log.warn("activeCodes is null for user {}", user.getId());
                return;
            }
            
            if (activeCodes.size() > 1) {
                log.warn("사용자 {}에 대해 중복 활성 초대 코드 {}개 발견, 정리 진행", 
                        user.getId(), activeCodes.size());
                
                // 가장 최신 코드(첫 번째)를 제외하고 나머지 만료
                for (int i = 1; i < activeCodes.size(); i++) {
                    InviteCode duplicateCode = activeCodes.get(i);
                    if (duplicateCode != null) {
                        duplicateCode.setStatus(InviteCode.InviteStatus.EXPIRED);
                        inviteCodeRepository.save(duplicateCode);
                    }
                }
                
                log.info("중복 활성 초대 코드 {}개 정리 완료: 사용자 {}", 
                        activeCodes.size() - 1, user.getId());
            }
        } catch (Exception e) {
            log.error("중복 활성 초대 코드 정리 중 오류 발생: 사용자 {}, 오류: {}", 
                    user != null ? user.getId() : "null", e.getMessage(), e);
            // 오류가 발생해도 메인 로직에 영향을 주지 않도록 예외를 삼킴
        }
    }
    
    public boolean isInviteCodeValid(String code) {
        return inviteCodeRepository.findByCodeAndStatus(code, InviteCode.InviteStatus.ACTIVE)
                .map(inviteCode -> !inviteCode.isExpired())
                .orElse(false);
    }
    
    public Map<String, Object> validateInviteCodeWithPartnerInfo(String code) {
        Map<String, Object> result = new HashMap<>();
        
        Optional<InviteCode> inviteCodeOpt = inviteCodeRepository.findByCodeAndStatus(code, InviteCode.InviteStatus.ACTIVE);
        
        if (inviteCodeOpt.isEmpty()) {
            result.put("isValid", false);
            result.put("message", "유효하지 않은 초대 코드입니다.");
            return result;
        }
        
        InviteCode inviteCode = inviteCodeOpt.get();
        
        if (inviteCode.isExpired()) {
            result.put("isValid", false);
            result.put("message", "만료된 초대 코드입니다.");
            return result;
        }
        
        User inviter = inviteCode.getInviter();
        result.put("isValid", true);
        result.put("message", "유효한 초대 코드입니다.");
        result.put("partnerName", inviter.getName());
        result.put("partnerNickname", inviter.getNickname());
        
        log.info("초대 코드 검증 성공: {} -> 파트너: {} ({})", code, inviter.getName(), inviter.getNickname());
        
        return result;
    }
    
    private String generateUniqueCode() {
        String code;
        do {
            code = String.format("%06d", secureRandom.nextInt(1000000));
        } while (inviteCodeRepository.existsByCode(code));
        return code;
    }
    
    // 만료된 초대 코드 정리 (1시간마다 실행)
    @Scheduled(fixedRate = 3600000)
    @Transactional
    public void cleanupExpiredCodes() {
        int expiredCount = inviteCodeRepository.expireOldCodes(LocalDateTime.now());
        if (expiredCount > 0) {
            log.info("만료된 초대 코드 {} 개 정리 완료", expiredCount);
        }
    }
}