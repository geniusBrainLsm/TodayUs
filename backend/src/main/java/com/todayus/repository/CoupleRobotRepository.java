package com.todayus.repository;

import com.todayus.entity.AiRobot;
import com.todayus.entity.Couple;
import com.todayus.entity.CoupleRobot;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CoupleRobotRepository extends JpaRepository<CoupleRobot, Long> {

    List<CoupleRobot> findByCouple(Couple couple);

    Optional<CoupleRobot> findByCoupleAndRobot(Couple couple, AiRobot robot);

    boolean existsByCoupleAndRobot(Couple couple, AiRobot robot);
}
