package com.todayus.security;

import com.todayus.entity.User;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.oauth2.core.user.OAuth2User;

import java.util.Collection;
import java.util.Map;

@RequiredArgsConstructor
@Getter
public class CustomOAuth2User implements OAuth2User {
    
    private final Collection<? extends GrantedAuthority> authorities;
    private final Map<String, Object> attributes;
    private final User user;
    
    @Override
    public Map<String, Object> getAttributes() {
        return attributes;
    }
    
    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return authorities;
    }
    
    @Override
    public String getName() {
        return user.getName();
    }
    
    public String getEmail() {
        return user.getEmail();
    }
    
    public Long getUserId() {
        return user.getId();
    }
}