package com.todayus.service;

import com.todayus.dto.StoreDto;
import com.todayus.entity.AiRobot;
import com.todayus.entity.Couple;
import com.todayus.entity.CoupleRobot;
import com.todayus.entity.User;
import com.todayus.repository.AiRobotRepository;
import com.todayus.repository.CoupleRepository;
import com.todayus.repository.CoupleRobotRepository;
import com.todayus.repository.UserRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class RobotStoreService {

    private final AiRobotRepository aiRobotRepository;
    private final UserRepository userRepository;
    private final CoupleRepository coupleRepository;
    private final CoupleRobotRepository coupleRobotRepository;

    public StoreDto.StoreOverview getStoreOverview(User user) {
        Couple couple = getCouple(user);
        ensureActiveRobot(couple);
        List<AiRobot> robots = aiRobotRepository.findAllByActiveTrueOrderByDisplayOrderAscNameAsc();
        Map<Long, Boolean> ownershipMap = buildOwnershipMap(couple);

        List<StoreDto.RobotSummary> summaries = robots.stream()
                .map(robot -> toRobotSummary(robot,
                        ownershipMap.getOrDefault(robot.getId(), Boolean.FALSE),
                        isActiveRobot(couple, robot)))
                .collect(Collectors.toList());

        return StoreDto.StoreOverview.builder()
                .oilBalance(couple.getOilBalance())
                .robots(summaries)
                .build();
    }

    public StoreDto.StoreOverview purchaseRobot(User user, Long robotId) {
        Couple couple = getCouple(user);
        AiRobot robot = findActiveRobot(robotId);
        ensureActiveRobot(couple);

        // 이미 구매한 로봇이면 활성화만 수행
        if (coupleRobotRepository.existsByCoupleAndRobot(couple, robot)) {
            couple.activateRobot(robot);
            coupleRepository.save(couple);
            return getStoreOverview(user);
        }

        // 오일 잔액 확인
        if (!couple.hasEnoughOil(robot.getPriceOil())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "보유한 오일이 부족합니다.");
        }

        // 오일 차감 및 로봇 활성화
        couple.spendOil(robot.getPriceOil());
        couple.activateRobot(robot);
        coupleRepository.save(couple);

        // 커플 로봇 구매 기록 생성
        coupleRobotRepository.save(CoupleRobot.builder()
                .couple(couple)
                .robot(robot)
                .build());

        log.info("커플 {}이(가) 로봇 {}을(를) 구매했습니다. 남은 오일: {}",
                couple.getId(), robot.getName(), couple.getOilBalance());

        return getStoreOverview(user);
    }

    public StoreDto.StoreOverview activateRobot(User user, Long robotId) {
        Couple couple = getCouple(user);
        AiRobot robot = findActiveRobot(robotId);
        ensureActiveRobot(couple);

        // 구매하지 않은 로봇인지 확인 (기본 로봇 제외)
        if (!coupleRobotRepository.existsByCoupleAndRobot(couple, robot) && !robot.isDefaultRobot()) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "아직 구매하지 않은 로봇입니다.");
        }

        couple.activateRobot(robot);
        coupleRepository.save(couple);
        return getStoreOverview(user);
    }

    public void grantOil(User user, int amount) {
        Couple couple = getCouple(user);
        if (amount <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "오일 충전량은 0보다 커야 합니다.");
        }
        couple.addOil(amount);
        coupleRepository.save(couple);
        log.info("커플 {}에게 오일 {}개 지급. 현재 잔액: {}", couple.getId(), amount, couple.getOilBalance());
    }

    public void deductOil(User user, int amount) {
        Couple couple = getCouple(user);
        if (amount <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "오일 차감량은 0보다 커야 합니다.");
        }
        if (!couple.hasEnoughOil(amount)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "보유한 오일이 부족합니다.");
        }
        couple.spendOil(amount);
        coupleRepository.save(couple);
        log.info("커플 {}에서 오일 {}개 차감. 현재 잔액: {}", couple.getId(), amount, couple.getOilBalance());
    }

    public List<AiRobot> getAllRobots() {
        return aiRobotRepository.findAll();
    }

    public AiRobot getRobot(Long robotId) {
        return aiRobotRepository.findById(robotId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "로봇을 찾을 수 없습니다."));
    }

    public AiRobot createRobot(AiRobot robot) {
        if (robot.getDefaultRobot() != null && robot.getDefaultRobot()) {
            clearExistingDefaultIfNecessary();
        }
        return aiRobotRepository.save(robot);
    }

    public AiRobot updateRobot(Long robotId, AiRobot payload) {
        AiRobot existing = getRobot(robotId);

        boolean requestedDefault = payload.getDefaultRobot() != null && payload.getDefaultRobot();
        if (requestedDefault && !existing.isDefaultRobot()) {
            clearExistingDefaultIfNecessary();
        }

        existing.setCode(payload.getCode());
        existing.setName(payload.getName());
        existing.setTagline(payload.getTagline());
        existing.setDescription(payload.getDescription());
        existing.setPriceOil(payload.getPriceOil());
        existing.setImageUrl(payload.getImageUrl());
        existing.setSplashImageUrl(payload.getSplashImageUrl());
        existing.setBeforeDiaryImageUrl(payload.getBeforeDiaryImageUrl());
        existing.setAfterDiaryImageUrl(payload.getAfterDiaryImageUrl());
        existing.setThemeColorHex(payload.getThemeColorHex());
        existing.setPreviewMessage(payload.getPreviewMessage());
        existing.setChatSystemPrompt(payload.getChatSystemPrompt());
        existing.setChatUserGuidance(payload.getChatUserGuidance());
        existing.setCommentSystemPrompt(payload.getCommentSystemPrompt());
        existing.setCommentUserGuidance(payload.getCommentUserGuidance());
        existing.setEmotionSystemPrompt(payload.getEmotionSystemPrompt());
        existing.setChatMaxTokens(payload.getChatMaxTokens());
        existing.setCommentMaxTokens(payload.getCommentMaxTokens());
        existing.setEmotionMaxTokens(payload.getEmotionMaxTokens());
        existing.setChatTemperature(payload.getChatTemperature());
        existing.setCommentTemperature(payload.getCommentTemperature());
        existing.setEmotionTemperature(payload.getEmotionTemperature());
        existing.setDefaultRobot(payload.getDefaultRobot() != null && payload.getDefaultRobot());
        existing.setActive(payload.getActive());
        existing.setDisplayOrder(payload.getDisplayOrder());

        return aiRobotRepository.save(existing);
    }

    public void deleteRobot(Long robotId) {
        aiRobotRepository.deleteById(robotId);
    }

    public AiRobot ensureActiveRobot(Couple couple) {
        AiRobot current = couple.getActiveRobot();
        if (current != null && current.isActive()) {
            return current;
        }

        // 기본 로봇 찾기
        AiRobot fallback = aiRobotRepository.findFirstByDefaultRobotTrue()
                .orElseGet(() -> aiRobotRepository.findAllByActiveTrueOrderByDisplayOrderAscNameAsc()
                        .stream()
                        .findFirst()
                        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "사용 가능한 로봇이 없습니다.")));

        couple.activateRobot(fallback);
        coupleRepository.save(couple);

        // 기본 로봇은 자동으로 소유
        if (!coupleRobotRepository.existsByCoupleAndRobot(couple, fallback)) {
            coupleRobotRepository.save(CoupleRobot.builder()
                    .couple(couple)
                    .robot(fallback)
                    .build());
        }
        return fallback;
    }

    /**
     * User 기반으로 로봇 초기화 (커플 찾아서 처리)
     * 관리자 등이 커플 연결 전에 호출할 때 사용
     */
    public AiRobot ensureActiveRobotForUser(User user) {
        Couple couple = getCouple(user);
        return ensureActiveRobot(couple);
    }

    private AiRobot findActiveRobot(Long robotId) {
        AiRobot robot = aiRobotRepository.findById(robotId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "로봇을 찾을 수 없습니다."));
        if (!robot.isActive()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "현재 구매할 수 없는 로봇입니다.");
        }
        return robot;
    }

    private Map<Long, Boolean> buildOwnershipMap(Couple couple) {
        Map<Long, Boolean> map = new HashMap<>();
        coupleRobotRepository.findByCouple(couple).forEach(ownership ->
                map.put(ownership.getRobot().getId(), Boolean.TRUE)
        );

        // 기본 로봇은 모두 소유
        aiRobotRepository.findAll().stream()
                .filter(AiRobot::isDefaultRobot)
                .forEach(defaultRobot -> map.put(defaultRobot.getId(), Boolean.TRUE));
        return map;
    }

    private boolean isActiveRobot(Couple couple, AiRobot robot) {
        AiRobot active = couple.getActiveRobot();
        return active != null && active.getId().equals(robot.getId());
    }

    private Couple getCouple(User user) {
        return coupleRepository.findByUser1OrUser2(user)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, "커플 연결이 필요합니다."));
    }

    private StoreDto.RobotSummary toRobotSummary(AiRobot robot, boolean owned, boolean active) {
        return StoreDto.RobotSummary.builder()
                .id(robot.getId())
                .code(robot.getCode())
                .name(robot.getName())
                .tagline(robot.getTagline())
                .description(robot.getDescription())
                .priceOil(robot.getPriceOil())
                .imageUrl(robot.getImageUrl())
                .splashImageUrl(robot.getSplashImageUrl())
                .beforeDiaryImageUrl(robot.getBeforeDiaryImageUrl())
                .afterDiaryImageUrl(robot.getAfterDiaryImageUrl())
                .themeColorHex(robot.getThemeColorHex())
                .previewMessage(robot.getPreviewMessage())
                .chatUserGuidance(robot.getChatUserGuidance())
                .commentUserGuidance(robot.getCommentUserGuidance())
                .chatMaxTokens(robot.getChatMaxTokens())
                .commentMaxTokens(robot.getCommentMaxTokens())
                .chatTemperature(robot.getChatTemperature())
                .commentTemperature(robot.getCommentTemperature())
                .owned(owned)
                .active(active)
                .build();
    }

    private void clearExistingDefaultIfNecessary() {
        aiRobotRepository.findFirstByDefaultRobotTrue().ifPresent(existing -> {
            existing.setDefaultRobot(Boolean.FALSE);
            aiRobotRepository.save(existing);
        });
    }
}
