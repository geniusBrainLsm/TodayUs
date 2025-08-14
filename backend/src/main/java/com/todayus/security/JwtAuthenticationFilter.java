package com.todayus.security;

import com.todayus.entity.User;
import com.todayus.repository.UserRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@Slf4j
@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {
    
    private final JwtTokenProvider jwtTokenProvider;
    private final UserRepository userRepository;
    
    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        
        String requestURI = request.getRequestURI();
        log.info("🔵 JWT 필터 처리 시작: {}", requestURI);
        
        String token = getTokenFromRequest(request);
        log.info("🔵 추출된 토큰: {}", token != null ? token.substring(0, Math.min(20, token.length())) + "..." : "null");
        log.info("🔵 요청 URI: {}", request.getRequestURI());
        log.info("🔵 Authorization 헤더: {}", request.getHeader("Authorization"));
        
        if (StringUtils.hasText(token)) {
            boolean isValid = jwtTokenProvider.validateToken(token);
            log.info("🔵 토큰 유효성 검사 결과: {}", isValid);
            
            if (isValid) {
                String userId = jwtTokenProvider.getUserId(token);
                String email = jwtTokenProvider.getEmail(token);
                
                // 데이터베이스에서 사용자 정보 조회
                Optional<User> userOptional = userRepository.findById(Long.valueOf(userId));
                
                if (userOptional.isPresent()) {
                    User user = userOptional.get();
                    
                    // CustomOAuth2User 객체 생성
                    Map<String, Object> attributes = new HashMap<>();
                    attributes.put("sub", userId);
                    attributes.put("email", email);
                    attributes.put("name", user.getName());
                    
                    CustomOAuth2User customUser = new CustomOAuth2User(
                        Collections.singletonList(new SimpleGrantedAuthority("ROLE_USER")),
                        attributes,
                        user
                    );
                    
                    // 인증 객체 생성
                    UsernamePasswordAuthenticationToken authentication = 
                        new UsernamePasswordAuthenticationToken(customUser, null, customUser.getAuthorities());
                    authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                    
                    // SecurityContext에 인증 정보 설정
                    SecurityContextHolder.getContext().setAuthentication(authentication);
                    
                    log.info("🟢 JWT 인증 성공: userId={}, email={}", userId, email);
                } else {
                    log.warn("🔴 JWT 토큰의 userId={}에 해당하는 사용자를 찾을 수 없음", userId);
                }
            } else {
                log.warn("🔴 JWT 토큰 검증 실패");
            }
        } else {
            log.info("🟡 JWT 토큰이 없음 - 익명 사용자로 처리");
        }
        
        filterChain.doFilter(request, response);
    }
    
    private String getTokenFromRequest(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");
        if (StringUtils.hasText(bearerToken) && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }
        return null;
    }
}