package com.todayus.service;

import com.todayus.dto.AnniversaryDto;
import com.todayus.entity.Couple;
import com.todayus.entity.User;
import com.todayus.repository.CoupleRepository;
import com.todayus.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.Optional;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class AnniversaryService {
    
    private final UserRepository userRepository;
    private final CoupleRepository coupleRepository;
    
    public AnniversaryDto.Response setAnniversary(String userEmail, LocalDate anniversaryDate) {
        User user = findUserByEmail(userEmail);
        Couple couple = findCoupleByUser(user);
        
        // 이미 기념일이 설정되어 있는 경우 확인
        if (couple.hasAnniversaryDate()) {
            log.warn("Anniversary already set for couple: {}", couple.getId());
            throw new IllegalStateException("기념일이 이미 설정되어 있습니다. 한 커플당 한 명만 기념일을 설정할 수 있습니다.");
        }
        
        // 기념일 유효성 검증
        validateAnniversaryDate(anniversaryDate);
        
        couple.updateAnniversaryDate(anniversaryDate, user);
        coupleRepository.save(couple);
        
        log.info("Anniversary set for couple: {} by user: {} with date: {}", couple.getId(), user.getEmail(), anniversaryDate);
        
        return AnniversaryDto.Response.from(anniversaryDate, couple.getDaysSinceAnniversary());
    }
    
    @Transactional(readOnly = true)
    public AnniversaryDto.Response getAnniversary(String userEmail) {
        User user = findUserByEmail(userEmail);
        Couple couple = findCoupleByUser(user);
        
        log.info("🟢 기념일 조회 시작 - 사용자: {}, 커플 ID: {}", userEmail, couple.getId());
        log.info("🟢 커플 기념일 날짜: {}", couple.getAnniversaryDate());
        log.info("🟢 기념일 설정자: {}", couple.getAnniversarySetter());
        log.info("🟢 hasAnniversaryDate: {}", couple.hasAnniversaryDate());
        
        AnniversaryDto.Response response = AnniversaryDto.Response.from(couple.getAnniversaryDate(), couple.getDaysSinceAnniversary());
        
        // 기념일 설정 상태 정보 추가
        if (couple.hasAnniversaryDate()) {
            response.setCanEdit(couple.isAnniversarySetBy(user));
            
            // 설정자 닉네임 조회
            String setterName = null;
            if (couple.getAnniversarySetter() != null) {
                setterName = couple.getAnniversarySetter().getNickname();
            }
            response.setSetterName(setterName);
            
            log.info("🟢 기념일 존재 - canEdit: {}, setterName: {}", response.getCanEdit(), response.getSetterName());
        } else {
            response.setCanEdit(true);
            response.setSetterName(null);
            log.info("🟡 기념일 없음 - canEdit: true, setterName: null");
        }
        
        log.info("🟢 응답 데이터: anniversaryDate={}, daysSince={}", response.getAnniversaryDate(), response.getDaysSince());
        return response;
    }
    
    public AnniversaryDto.Response updateAnniversary(String userEmail, LocalDate anniversaryDate) {
        User user = findUserByEmail(userEmail);
        Couple couple = findCoupleByUser(user);
        
        // 기념일을 설정한 사용자인지 확인
        if (!couple.isAnniversarySetBy(user)) {
            log.warn("User {} attempted to update anniversary not set by them for couple: {}", user.getEmail(), couple.getId());
            throw new IllegalStateException("기념일은 설정한 사용자만 수정할 수 있습니다.");
        }
        
        // 기념일 유효성 검증
        validateAnniversaryDate(anniversaryDate);
        
        couple.updateAnniversaryDate(anniversaryDate, user);
        coupleRepository.save(couple);
        
        log.info("Anniversary updated for couple: {} by user: {} with date: {}", couple.getId(), user.getEmail(), anniversaryDate);
        
        return AnniversaryDto.Response.from(anniversaryDate, couple.getDaysSinceAnniversary());
    }
    
    public void deleteAnniversary(String userEmail) {
        User user = findUserByEmail(userEmail);
        Couple couple = findCoupleByUser(user);
        
        // 기념일을 설정한 사용자인지 확인
        if (!couple.isAnniversarySetBy(user)) {
            log.warn("User {} attempted to delete anniversary not set by them for couple: {}", user.getEmail(), couple.getId());
            throw new IllegalStateException("기념일은 설정한 사용자만 삭제할 수 있습니다.");
        }
        
        couple.updateAnniversaryDate(null, null);
        coupleRepository.save(couple);
        
        log.info("Anniversary deleted for couple: {} by user: {}", couple.getId(), user.getEmail());
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
            throw new IllegalStateException("커플 관계가 설정되지 않았습니다. 먼저 커플 연결을 완료해주세요.");
        }
        
        Couple couple = coupleOpt.get();
        if (couple.getStatus() != Couple.CoupleStatus.CONNECTED) {
            log.warn("Couple {} is not in CONNECTED status", couple.getId());
            throw new IllegalStateException("커플 관계가 연결되지 않은 상태입니다.");
        }
        
        return couple;
    }
    
    private void validateAnniversaryDate(LocalDate anniversaryDate) {
        if (anniversaryDate.isAfter(LocalDate.now())) {
            throw new IllegalArgumentException("기념일은 현재 날짜 이전이어야 합니다.");
        }
        
        LocalDate fiftyYearsAgo = LocalDate.now().minusYears(50);
        if (anniversaryDate.isBefore(fiftyYearsAgo)) {
            throw new IllegalArgumentException("기념일이 너무 오래된 날짜입니다.");
        }
    }
}