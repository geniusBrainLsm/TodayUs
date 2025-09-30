package com.todayus.repository;

import com.todayus.entity.AiRobot;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AiRobotRepository extends JpaRepository<AiRobot, Long> {
    Optional<AiRobot> findByCode(String code);

    Optional<AiRobot> findFirstByDefaultRobotTrue();

    List<AiRobot> findAllByActiveTrueOrderByDisplayOrderAscNameAsc();
}
