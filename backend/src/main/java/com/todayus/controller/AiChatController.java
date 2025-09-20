package com.todayus.controller;

import com.todayus.dto.AiChatDto;
import com.todayus.security.CustomOAuth2User;
import com.todayus.service.AiChatService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Slf4j
@RestController
@RequestMapping("/api/ai")
@RequiredArgsConstructor
public class AiChatController {

    private final AiChatService aiChatService;

    @PostMapping("/chat")
    public ResponseEntity<AiChatDto.Response> chat(
            @AuthenticationPrincipal CustomOAuth2User user,
            @Valid @RequestBody AiChatDto.Request request
    ) {
        if (user == null) {
            return ResponseEntity.status(401).build();
        }

        log.info("AI chat requested by user: {}", user.getEmail());
        AiChatDto.Response response = aiChatService.chat(user.getEmail(), request);
        return ResponseEntity.ok(response);
    }
}
