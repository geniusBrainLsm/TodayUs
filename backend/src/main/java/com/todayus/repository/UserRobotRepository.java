package com.todayus.repository;

import com.todayus.entity.AiRobot;
import com.todayus.entity.User;
import com.todayus.entity.UserRobot;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserRobotRepository extends JpaRepository<UserRobot, Long> {

    boolean existsByUserAndRobot(User user, AiRobot robot);

    Optional<UserRobot> findByUserAndRobot(User user, AiRobot robot);

    List<UserRobot> findByUser(User user);
}
