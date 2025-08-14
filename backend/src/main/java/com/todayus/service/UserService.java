package com.todayus.service;

import com.todayus.dto.UserDto;
import com.todayus.entity.User;
import com.todayus.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserService {
    
    private final UserRepository userRepository;
    
    public Optional<UserDto> findById(Long userId) {
        return userRepository.findById(userId)
                .map(UserDto::from);
    }
    
    @Transactional
    public UserDto updateNickname(Long userId, String nickname) {
        if (userRepository.existsByNickname(nickname)) {
            throw new IllegalArgumentException("이미 사용중인 닉네임입니다.");
        }
        
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
        
        user.updateNickname(nickname);
        User savedUser = userRepository.save(user);
        
        log.info("사용자 {} 닉네임 업데이트: {}", userId, nickname);
        return UserDto.from(savedUser);
    }
    
    public boolean isNicknameAvailable(String nickname) {
        return !userRepository.existsByNickname(nickname);
    }
}