package com.todayus.service;

import com.todayus.dto.TimeCapsuleDto;
import com.todayus.entity.Couple;
import com.todayus.entity.TimeCapsule;
import com.todayus.entity.User;
import com.todayus.repository.CoupleRepository;
import com.todayus.repository.TimeCapsuleRepository;
import com.todayus.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class TimeCapsuleService {
    
    private final TimeCapsuleRepository timeCapsuleRepository;
    private final UserRepository userRepository;
    private final CoupleRepository coupleRepository;
    
    /**
     * 타임캡슐 생성
     */
    public TimeCapsuleDto.Response createTimeCapsule(String userEmail, TimeCapsuleDto.CreateRequest request) {
        User user = findUserByEmail(userEmail);
        Couple couple = findCoupleByUser(user);
        
        // 오픈 날짜 검증 (최소 내일부터 가능)
        if (request.getOpenDate().isBefore(LocalDate.now().plusDays(1))) {
            throw new IllegalStateException("타임캡슐 오픈 날짜는 최소 내일부터 설정할 수 있습니다.");
        }
        
        TimeCapsule timeCapsule = TimeCapsule.builder()
                .couple(couple)
                .author(user)
                .title(request.getTitle())
                .content(request.getContent())
                .openDate(request.getOpenDate())
                .type(request.getType())
                .build();
        
        TimeCapsule savedTimeCapsule = timeCapsuleRepository.save(timeCapsule);
        
        log.info("Time capsule created: {} by user: {} with open date: {}", 
                savedTimeCapsule.getId(), userEmail, request.getOpenDate());
        
        return TimeCapsuleDto.Response.from(savedTimeCapsule);
    }
    
    /**
     * 타임캡슐 목록 조회 (커플)
     */
    @Transactional(readOnly = true)
    public Page<TimeCapsuleDto.ListResponse> getTimeCapsules(String userEmail, int page, int size) {
        User user = findUserByEmail(userEmail);
        Couple couple = findCoupleByUser(user);
        
        Pageable pageable = PageRequest.of(page, size);
        Page<TimeCapsule> timeCapsules = timeCapsuleRepository.findByCoupleOrderByCreatedAtDesc(couple, pageable);
        
        return timeCapsules.map(TimeCapsuleDto.ListResponse::from);
    }
    
    /**
     * 타임캡슐 상세 조회
     */
    @Transactional(readOnly = true)
    public TimeCapsuleDto.Response getTimeCapsule(String userEmail, Long timeCapsuleId) {
        User user = findUserByEmail(userEmail);
        Couple couple = findCoupleByUser(user);
        
        TimeCapsule timeCapsule = findTimeCapsuleById(timeCapsuleId);
        
        // 권한 확인 (같은 커플의 타임캡슐인지)
        if (!timeCapsule.getCouple().getId().equals(couple.getId())) {
            throw new IllegalStateException("타임캡슐에 접근할 권한이 없습니다.");
        }
        
        return TimeCapsuleDto.Response.from(timeCapsule);
    }
    
    /**
     * 타임캡슐 열기
     */
    public TimeCapsuleDto.Response openTimeCapsule(String userEmail, Long timeCapsuleId) {
        User user = findUserByEmail(userEmail);
        Couple couple = findCoupleByUser(user);
        
        TimeCapsule timeCapsule = findTimeCapsuleById(timeCapsuleId);
        
        // 권한 확인
        if (!timeCapsule.getCouple().getId().equals(couple.getId())) {
            throw new IllegalStateException("타임캡슐에 접근할 권한이 없습니다.");
        }
        
        // 오픈 가능 여부 확인
        if (!timeCapsule.canOpen()) {
            if (timeCapsule.getIsOpened()) {
                throw new IllegalStateException("이미 열린 타임캡슐입니다.");
            } else {
                throw new IllegalStateException("아직 열 수 없는 타임캡슐입니다.");
            }
        }
        
        timeCapsule.open();
        
        log.info("Time capsule opened: {} by user: {}", timeCapsuleId, userEmail);
        
        return TimeCapsuleDto.Response.from(timeCapsule);
    }
    
    /**
     * 열 수 있는 타임캡슐 목록 조회
     */
    @Transactional(readOnly = true)
    public List<TimeCapsuleDto.ListResponse> getOpenableTimeCapsules(String userEmail) {
        User user = findUserByEmail(userEmail);
        Couple couple = findCoupleByUser(user);
        
        List<TimeCapsule> openableTimeCapsules = timeCapsuleRepository
                .findOpenableTimeCapsules(couple, LocalDate.now());
        
        return openableTimeCapsules.stream()
                .map(TimeCapsuleDto.ListResponse::from)
                .collect(Collectors.toList());
    }
    
    /**
     * 타임캡슐 요약 정보 조회
     */
    @Transactional(readOnly = true)
    public TimeCapsuleDto.Summary getTimeCapsuleSummary(String userEmail) {
        User user = findUserByEmail(userEmail);
        Couple couple = findCoupleByUser(user);
        
        long totalCount = timeCapsuleRepository.countByCouple(couple);
        long openedCount = timeCapsuleRepository.countByCoupleAndIsOpenedTrue(couple);
        long unopenedCount = timeCapsuleRepository.countByCoupleAndIsOpenedFalse(couple);
        
        List<TimeCapsule> openableTimeCapsules = timeCapsuleRepository
                .findOpenableTimeCapsules(couple, LocalDate.now());
        long openableCount = openableTimeCapsules.size();
        
        return TimeCapsuleDto.Summary.builder()
                .totalCount(totalCount)
                .openedCount(openedCount)
                .unopenedCount(unopenedCount)
                .openableCount(openableCount)
                .build();
    }
    
    /**
     * 타임캡슐 삭제
     */
    public void deleteTimeCapsule(String userEmail, Long timeCapsuleId) {
        User user = findUserByEmail(userEmail);
        TimeCapsule timeCapsule = findTimeCapsuleById(timeCapsuleId);
        
        // 본인이 작성한 타임캡슐만 삭제 가능
        if (!timeCapsule.getAuthor().equals(user)) {
            throw new IllegalStateException("본인이 작성한 타임캡슐만 삭제할 수 있습니다.");
        }
        
        // 이미 열린 타임캡슐은 삭제 불가
        if (timeCapsule.getIsOpened()) {
            throw new IllegalStateException("이미 열린 타임캡슐은 삭제할 수 없습니다.");
        }
        
        timeCapsuleRepository.delete(timeCapsule);
        
        log.info("Time capsule deleted: {} by user: {}", timeCapsuleId, userEmail);
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
    
    private TimeCapsule findTimeCapsuleById(Long timeCapsuleId) {
        return timeCapsuleRepository.findById(timeCapsuleId)
                .orElseThrow(() -> {
                    log.error("Time capsule not found with id: {}", timeCapsuleId);
                    return new IllegalStateException("타임캡슐을 찾을 수 없습니다.");
                });
    }
}