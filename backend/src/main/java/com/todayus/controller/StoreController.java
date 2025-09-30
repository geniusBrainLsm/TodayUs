package com.todayus.controller;

import com.todayus.dto.StoreDto;
import com.todayus.entity.User;
import com.todayus.repository.UserRepository;
import com.todayus.security.CustomOAuth2User;
import com.todayus.service.RobotStoreService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import static org.springframework.http.HttpStatus.UNAUTHORIZED;

@RestController
@RequestMapping("/api/store")
@RequiredArgsConstructor
public class StoreController {

    private final RobotStoreService robotStoreService;
    private final UserRepository userRepository;

    @GetMapping("/robots")
    public ResponseEntity<StoreDto.StoreOverview> getRobots(
            @AuthenticationPrincipal CustomOAuth2User principal) {
        User user = loadUser(principal);
        return ResponseEntity.ok(robotStoreService.getStoreOverview(user));
    }

    @PostMapping("/purchase/{robotId}")
    public ResponseEntity<StoreDto.StoreOverview> purchaseRobot(
            @AuthenticationPrincipal CustomOAuth2User principal,
            @PathVariable Long robotId) {
        User user = loadUser(principal);
        StoreDto.StoreOverview overview = robotStoreService.purchaseRobot(user, robotId);
        return ResponseEntity.ok(overview);
    }

    @PostMapping("/activate/{robotId}")
    public ResponseEntity<StoreDto.StoreOverview> activateRobot(
            @AuthenticationPrincipal CustomOAuth2User principal,
            @PathVariable Long robotId) {
        User user = loadUser(principal);
        StoreDto.StoreOverview overview = robotStoreService.activateRobot(user, robotId);
        return ResponseEntity.ok(overview);
    }

    private User loadUser(CustomOAuth2User principal) {
        if (principal == null || principal.getUserId() == null) {
            throw new ResponseStatusException(UNAUTHORIZED, "로그인이 필요합니다.");
        }
        return userRepository.findById(principal.getUserId())
                .orElseThrow(() -> new ResponseStatusException(UNAUTHORIZED, "사용자를 찾을 수 없습니다."));
    }
}
