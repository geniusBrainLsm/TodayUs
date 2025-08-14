package com.todayus.repository;

import com.todayus.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    
    Optional<User> findByEmail(String email);
    
    Optional<User> findByProviderAndProviderId(User.Provider provider, String providerId);
    
    boolean existsByEmail(String email);
    
    boolean existsByNickname(String nickname);
}