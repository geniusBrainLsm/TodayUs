package com.todayus.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.todayus.entity.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.Authentication;
import org.springframework.security.web.authentication.SimpleUrlAuthenticationSuccessHandler;
import org.springframework.stereotype.Component;
import org.springframework.web.util.UriComponentsBuilder;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

@Slf4j
@Component
@RequiredArgsConstructor
public class OAuth2AuthenticationSuccessHandler extends SimpleUrlAuthenticationSuccessHandler {
    
    private final JwtTokenProvider jwtTokenProvider;
    
    @Value("${app.oauth2.authorized-redirect-uris[0]:http://localhost:3000}")
    private String redirectUri;
    
    @Override
    public void onAuthenticationSuccess(HttpServletRequest request, HttpServletResponse response, 
                                      Authentication authentication) throws IOException, ServletException {
        
        try {
            CustomOAuth2User oauth2User = (CustomOAuth2User) authentication.getPrincipal();
            User user = oauth2User.getUser();
            
            String token = jwtTokenProvider.createToken(
                    user.getId().toString(),
                    user.getEmail()
            );
            
            log.info("OAuth2 로그인 성공: 사용자 {}, 닉네임 설정 여부: {}", 
                    user.getEmail(), user.getNicknameSet());
            
            // 닉네임 설정 여부에 따라 리다이렉트 URL 결정
            String targetUrl;
            if (!user.getNicknameSet()) {
                // 닉네임 미설정 시 닉네임 입력 화면으로
                targetUrl = UriComponentsBuilder.fromUriString(redirectUri)
                        .path("/nickname-input")
                        .queryParam("token", token)
                        .build().toUriString();
            } else {
                // 닉네임 설정 완료 시 메인화면으로
                targetUrl = UriComponentsBuilder.fromUriString(redirectUri)
                        .path("/home")
                        .queryParam("token", token)
                        .build().toUriString();
            }
            
            log.info("OAuth2 로그인 후 리다이렉트: {}", targetUrl);
            getRedirectStrategy().sendRedirect(request, response, targetUrl);
            
        } catch (Exception e) {
            log.error("OAuth2 로그인 성공 처리 중 오류 발생", e);
            
            String errorUrl = UriComponentsBuilder.fromUriString(redirectUri)
                    .path("/login")
                    .queryParam("error", URLEncoder.encode("로그인 처리 중 오류가 발생했습니다.", StandardCharsets.UTF_8))
                    .build().toUriString();
            
            getRedirectStrategy().sendRedirect(request, response, errorUrl);
        }
    }
}