package com.todayus.controller;

import com.todayus.dto.RobotAdminDto;
import com.todayus.dto.StoreDto;
import com.todayus.entity.User;
import com.todayus.repository.UserRepository;
import com.todayus.security.CustomOAuth2User;
import com.todayus.service.RobotStoreService;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.stream.Collectors;

import static org.springframework.http.HttpStatus.FORBIDDEN;
import static org.springframework.http.HttpStatus.UNAUTHORIZED;

@RestController
@RequestMapping("/api/admin/store")
@RequiredArgsConstructor
public class AdminRobotController {

    private final RobotStoreService robotStoreService;
    private final UserRepository userRepository;

    @GetMapping("/robots")
    public ResponseEntity<List<RobotAdminDto.Response>> getRobots(
            @AuthenticationPrincipal CustomOAuth2User principal) {
        loadAdmin(principal);
        return ResponseEntity.ok(robotStoreService.getAllRobots().stream()
                .map(RobotAdminDto.Response::from)
                .collect(Collectors.toList()));
    }

    @PostMapping("/robots")
    public ResponseEntity<RobotAdminDto.Response> createRobot(
            @AuthenticationPrincipal CustomOAuth2User principal,
            @RequestBody RobotAdminDto.Request request) {
        loadAdmin(principal);
        RobotAdminDto.Response response = RobotAdminDto.Response.from(
                robotStoreService.createRobot(request.toEntity()));
        return ResponseEntity.ok(response);
    }

    @PutMapping("/robots/{robotId}")
    public ResponseEntity<RobotAdminDto.Response> updateRobot(
            @AuthenticationPrincipal CustomOAuth2User principal,
            @PathVariable Long robotId,
            @RequestBody RobotAdminDto.Request request) {
        loadAdmin(principal);
        RobotAdminDto.Response response = RobotAdminDto.Response.from(
                robotStoreService.updateRobot(robotId, request.toEntity()));
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/robots/{robotId}")
    public ResponseEntity<Void> deleteRobot(
            @AuthenticationPrincipal CustomOAuth2User principal,
            @PathVariable Long robotId) {
        loadAdmin(principal);
        robotStoreService.deleteRobot(robotId);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/users/{userId}/oil")
    public ResponseEntity<StoreDto.StoreOverview> adjustUserOil(
            @AuthenticationPrincipal CustomOAuth2User principal,
            @PathVariable Long userId,
            @RequestBody OilAdjustmentRequest request) {
        loadAdmin(principal);
        User target = userRepository.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(FORBIDDEN, "대상 사용자를 찾을 수 없습니다."));

        if (request.isDeduct()) {
            robotStoreService.deductOil(target, request.getAmount());
        } else {
            robotStoreService.grantOil(target, request.getAmount());
        }
        return ResponseEntity.ok(robotStoreService.getStoreOverview(target));
    }

    private User loadAdmin(CustomOAuth2User principal) {
        if (principal == null || principal.getUserId() == null) {
            throw new ResponseStatusException(UNAUTHORIZED, "로그인이 필요합니다.");
        }
        User user = userRepository.findById(principal.getUserId())
                .orElseThrow(() -> new ResponseStatusException(UNAUTHORIZED, "사용자를 찾을 수 없습니다."));
        if (user.getRole() != User.Role.ADMIN) {
            throw new ResponseStatusException(FORBIDDEN, "관리자 권한이 필요합니다.");
        }
        return user;
    }

    @Getter
    @Setter
    public static class OilAdjustmentRequest {
        private int amount;
        private boolean deduct;
    }
}
