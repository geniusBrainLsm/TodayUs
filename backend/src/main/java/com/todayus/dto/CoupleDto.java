package com.todayus.dto;

import com.todayus.entity.Couple;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CoupleDto {
    
    private Long id;
    private UserDto partner;
    private Couple.CoupleStatus status;
    private LocalDateTime connectedAt;
    private LocalDateTime createdAt;
    
    public static CoupleDto from(Couple couple, UserDto partner) {
        return CoupleDto.builder()
                .id(couple.getId())
                .partner(partner)
                .status(couple.getStatus())
                .connectedAt(couple.getConnectedAt())
                .createdAt(couple.getCreatedAt())
                .build();
    }
}