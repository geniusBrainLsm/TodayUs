package com.todayus.dto;

import com.todayus.entity.InviteCode;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class InviteCodeDto {
    
    private Long id;
    private String code;
    private UserDto inviter;
    private LocalDateTime expiresAt;
    private InviteCode.InviteStatus status;
    private LocalDateTime createdAt;
    
    public static InviteCodeDto from(InviteCode inviteCode) {
        if (inviteCode == null) {
            throw new IllegalArgumentException("InviteCode cannot be null");
        }
        
        return InviteCodeDto.builder()
                .id(inviteCode.getId())
                .code(inviteCode.getCode())
                .inviter(inviteCode.getInviter() != null ? UserDto.from(inviteCode.getInviter()) : null)
                .expiresAt(inviteCode.getExpiresAt())
                .status(inviteCode.getStatus())
                .createdAt(inviteCode.getCreatedAt())
                .build();
    }
    
    @Getter
    @NoArgsConstructor
    @Builder
    public static class CreateRequest {
        // 현재는 특별한 요청 필드가 없지만, 향후 확장을 위해 준비
    }
    
    @Getter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class UseRequest {
        private String code;
    }
}