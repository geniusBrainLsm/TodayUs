package com.todayus.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.util.Date;

@Slf4j
@Component
public class JwtTokenProvider {
    
    private final SecretKey secretKey;
    private final long tokenValidityInMilliseconds;
    
    public JwtTokenProvider(@Value("${jwt.secret:mySecretKey}") String secret,
                           @Value("${jwt.token-validity-in-seconds:86400}") long tokenValidityInSeconds) {
        this.secretKey = Keys.hmacShaKeyFor(secret.getBytes());
        this.tokenValidityInMilliseconds = tokenValidityInSeconds * 1000;
    }
    
    public String createToken(String userId, String email) {
        Date now = new Date();
        Date validity = new Date(now.getTime() + tokenValidityInMilliseconds);
        
        return Jwts.builder()
                .subject(userId)
                .claim("email", email)
                .issuedAt(now)
                .expiration(validity)
                .signWith(secretKey)
                .compact();
    }
    
    public String getUserId(String token) {
        return Jwts.parser()
                .verifyWith(secretKey)
                .build()
                .parseSignedClaims(token)
                .getPayload()
                .getSubject();
    }
    
    public String getEmail(String token) {
        return Jwts.parser()
                .verifyWith(secretKey)
                .build()
                .parseSignedClaims(token)
                .getPayload()
                .get("email", String.class);
    }

    public String getUsername(String token) {
        return Jwts.parser()
                .verifyWith(secretKey)
                .build()
                .parseSignedClaims(token)
                .getPayload()
                .get("name", String.class);
    }
    
    public boolean validateToken(String token) {
        try {
            log.info("🔵 JWT 토큰 검증 시작");
            Claims claims = Jwts.parser()
                .verifyWith(secretKey)
                .build()
                .parseSignedClaims(token)
                .getPayload();
            
            log.info("🟢 JWT 토큰 검증 성공 - Subject: {}, Expiration: {}", 
                     claims.getSubject(), claims.getExpiration());
            return true;
        } catch (ExpiredJwtException e) {
            log.error("🔴 JWT 토큰 만료: {}", e.getMessage());
            return false;
        } catch (UnsupportedJwtException e) {
            log.error("🔴 지원되지 않는 JWT 토큰: {}", e.getMessage());
            return false;
        } catch (MalformedJwtException e) {
            log.error("🔴 잘못된 형식의 JWT 토큰: {}", e.getMessage());
            return false;
        } catch (SecurityException e) {
            log.error("🔴 JWT 토큰 서명 검증 실패: {}", e.getMessage());
            return false;
        } catch (IllegalArgumentException e) {
            log.error("🔴 JWT 토큰이 비어있음: {}", e.getMessage());
            return false;
        } catch (JwtException e) {
            log.error("🔴 JWT 토큰 검증 실패: {}", e.getMessage());
            return false;
        }
    }
}