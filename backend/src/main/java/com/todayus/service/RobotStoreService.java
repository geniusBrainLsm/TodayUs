package com.todayus.service;

import com.todayus.dto.StoreDto;
import com.todayus.entity.AiRobot;
import com.todayus.entity.User;
import com.todayus.entity.UserRobot;
import com.todayus.repository.AiRobotRepository;
import com.todayus.repository.UserRepository;
import com.todayus.repository.UserRobotRepository;
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
    private final UserRobotRepository userRobotRepository;

    public StoreDto.StoreOverview getStoreOverview(User user) {
        ensureActiveRobot(user);
        List<AiRobot> robots = aiRobotRepository.findAllByActiveTrueOrderByDisplayOrderAscNameAsc();
        Map<Long, Boolean> ownershipMap = buildOwnershipMap(user);

        List<StoreDto.RobotSummary> summaries = robots.stream()
                .map(robot -> toRobotSummary(robot,
                        ownershipMap.getOrDefault(robot.getId(), Boolean.FALSE),
                        isActiveRobot(user, robot)))
                .collect(Collectors.toList());

        return StoreDto.StoreOverview.builder()
                .oilBalance(user.getOilBalance())
                .robots(summaries)
                .build();
    }

    public StoreDto.StoreOverview purchaseRobot(User user, Long robotId) {
        AiRobot robot = findActiveRobot(robotId);
        ensureActiveRobot(user);

        if (userRobotRepository.existsByUserAndRobot(user, robot)) {
            user.activateRobot(robot);
            userRepository.save(user);
            return getStoreOverview(user);
        }

        if (!user.hasEnoughOil(robot.getPriceOil())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "보유한 오일이 부족합니다.");
        }

        user.spendOil(robot.getPriceOil());
        user.activateRobot(robot);
        userRepository.save(user);

        userRobotRepository.save(UserRobot.builder()
                .user(user)
                .robot(robot)
                .build());

        return getStoreOverview(user);
    }

    public StoreDto.StoreOverview activateRobot(User user, Long robotId) {
        AiRobot robot = findActiveRobot(robotId);
        ensureActiveRobot(user);

        if (!userRobotRepository.existsByUserAndRobot(user, robot) && !robot.isDefaultRobot()) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "아직 구매하지 않은 로봇입니다.");
        }

        user.activateRobot(robot);
        userRepository.save(user);
        return getStoreOverview(user);
    }

    public void grantOil(User user, int amount) {
        if (amount <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "오일 충전량은 0보다 커야 합니다.");
        }
        user.addOil(amount);
        userRepository.save(user);
    }

    public void deductOil(User user, int amount) {
        if (amount <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "오일 차감량은 0보다 커야 합니다.");
        }
        if (!user.hasEnoughOil(amount)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "보유한 오일이 부족합니다.");
        }
        user.spendOil(amount);
        userRepository.save(user);
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

    public AiRobot ensureActiveRobot(User user) {
        AiRobot current = user.getActiveRobot();
        if (current != null && current.isActive()) {
            return current;
        }

        AiRobot fallback = aiRobotRepository.findFirstByDefaultRobotTrue()
                .orElseGet(() -> aiRobotRepository.findAllByActiveTrueOrderByDisplayOrderAscNameAsc()
                        .stream()
                        .findFirst()
                        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "사용 가능한 로봇이 없습니다.")));

        user.activateRobot(fallback);
        userRepository.save(user);

        if (!userRobotRepository.existsByUserAndRobot(user, fallback)) {
            userRobotRepository.save(UserRobot.builder()
                    .user(user)
                    .robot(fallback)
                    .build());
        }
        return fallback;
    }

    private AiRobot findActiveRobot(Long robotId) {
        AiRobot robot = aiRobotRepository.findById(robotId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "로봇을 찾을 수 없습니다."));
        if (!robot.isActive()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "현재 구매할 수 없는 로봇입니다.");
        }
        return robot;
    }

    private Map<Long, Boolean> buildOwnershipMap(User user) {
        Map<Long, Boolean> map = new HashMap<>();
        userRobotRepository.findByUser(user).forEach(ownership ->
                map.put(ownership.getRobot().getId(), Boolean.TRUE)
        );

        aiRobotRepository.findAll().stream()
                .filter(AiRobot::isDefaultRobot)
                .forEach(defaultRobot -> map.put(defaultRobot.getId(), Boolean.TRUE));
        return map;
    }

    private boolean isActiveRobot(User user, AiRobot robot) {
        AiRobot active = user.getActiveRobot();
        return active != null && active.getId().equals(robot.getId());
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
