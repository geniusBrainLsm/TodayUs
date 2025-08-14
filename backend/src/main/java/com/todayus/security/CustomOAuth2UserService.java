package com.todayus.security;

import com.todayus.entity.User;
import com.todayus.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.oauth2.client.userinfo.DefaultOAuth2UserService;
import org.springframework.security.oauth2.client.userinfo.OAuth2UserRequest;
import org.springframework.security.oauth2.core.OAuth2AuthenticationException;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.stereotype.Service;

import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class CustomOAuth2UserService extends DefaultOAuth2UserService {
    
    private final UserRepository userRepository;
    
    @Override
    public OAuth2User loadUser(OAuth2UserRequest userRequest) throws OAuth2AuthenticationException {
        OAuth2User oauth2User = super.loadUser(userRequest);
        
        String registrationId = userRequest.getClientRegistration().getRegistrationId();
        User.Provider provider = User.Provider.valueOf(registrationId.toUpperCase());
        
        UserInfo userInfo = extractUserInfo(oauth2User, provider);
        User user = saveOrUpdateUser(userInfo, provider);
        
        return new CustomOAuth2User(oauth2User.getAuthorities(), oauth2User.getAttributes(), user);
    }
    
    private UserInfo extractUserInfo(OAuth2User oauth2User, User.Provider provider) {
        Map<String, Object> attributes = oauth2User.getAttributes();
        log.info("OAuth2 Provider: {}, Attributes: {}", provider, attributes);
        
        switch (provider) {
            case GOOGLE:
                return UserInfo.builder()
                        .id((String) attributes.get("sub"))
                        .email((String) attributes.get("email"))
                        .name((String) attributes.get("name"))
                        .profileImageUrl((String) attributes.get("picture"))
                        .build();
                        
            case KAKAO:
                Map<String, Object> kakaoAccount = (Map<String, Object>) attributes.get("kakao_account");
                Map<String, Object> profile = (Map<String, Object>) kakaoAccount.get("profile");
                
                String email = null;
                if (kakaoAccount.containsKey("email")) {
                    email = (String) kakaoAccount.get("email");
                }
                
                return UserInfo.builder()
                        .id(String.valueOf(attributes.get("id")))
                        .email(email)
                        .name((String) profile.get("nickname"))
                        .profileImageUrl((String) profile.get("profile_image_url"))
                        .build();
                        
            default:
                throw new OAuth2AuthenticationException("지원하지 않는 소셜 로그인입니다: " + provider);
        }
    }
    
    private User saveOrUpdateUser(UserInfo userInfo, User.Provider provider) {
        return userRepository.findByProviderAndProviderId(provider, userInfo.getId())
                .map(existingUser -> existingUser.updateProfile(userInfo.getName(), userInfo.getProfileImageUrl()))
                .orElseGet(() -> userRepository.save(
                        User.builder()
                                .email(userInfo.getEmail())
                                .name(userInfo.getName())
                                .profileImageUrl(userInfo.getProfileImageUrl())
                                .provider(provider)
                                .providerId(userInfo.getId())
                                .role(User.Role.USER)
                                .build()
                ));
    }
    
    @lombok.Builder
    @lombok.Getter
    private static class UserInfo {
        private String id;
        private String email;
        private String name;
        private String profileImageUrl;
    }
}