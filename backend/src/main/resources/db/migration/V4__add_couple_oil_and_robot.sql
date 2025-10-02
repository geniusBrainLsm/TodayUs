-- Couple 테이블에 오일과 활성 로봇 필드 추가
-- 먼저 NULL 허용으로 추가
ALTER TABLE couples
ADD COLUMN IF NOT EXISTS oil_balance INTEGER,
ADD COLUMN IF NOT EXISTS active_robot_id BIGINT;

-- 기존 데이터에 기본값 설정
UPDATE couples SET oil_balance = 0 WHERE oil_balance IS NULL;

-- NOT NULL 제약조건 추가
ALTER TABLE couples
ALTER COLUMN oil_balance SET NOT NULL,
ALTER COLUMN oil_balance SET DEFAULT 0;

-- CoupleRobot 테이블 생성
CREATE TABLE couple_robots (
    id BIGSERIAL PRIMARY KEY,
    couple_id BIGINT NOT NULL,
    robot_id BIGINT NOT NULL,
    purchased_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_couple_robot UNIQUE (couple_id, robot_id)
);

-- 기존 User의 oilBalance를 Couple로 마이그레이션
-- user1의 오일을 커플 오일로 설정 (user1이 대표로 가정)
UPDATE couples c
SET oil_balance = (
    SELECT COALESCE(u.oil_balance, 0)
    FROM users u
    WHERE u.id = c.user1_id
);

-- 기존 User의 activeRobot을 Couple로 마이그레이션
UPDATE couples c
SET active_robot_id = (
    SELECT u.active_robot_id
    FROM users u
    WHERE u.id = c.user1_id
    LIMIT 1
);

-- 기존 UserRobot을 CoupleRobot으로 마이그레이션
INSERT INTO couple_robots (couple_id, robot_id, purchased_at)
SELECT DISTINCT c.id, ur.robot_id, ur.purchased_at
FROM user_robots ur
JOIN users u ON ur.user_id = u.id
JOIN couples c ON c.user1_id = u.id OR c.user2_id = u.id
ON CONFLICT (couple_id, robot_id) DO NOTHING;

-- 인덱스 추가
CREATE INDEX idx_couple_robots_couple_id ON couple_robots(couple_id);
CREATE INDEX idx_couple_robots_robot_id ON couple_robots(robot_id);
CREATE INDEX idx_couples_active_robot_id ON couples(active_robot_id);

-- 참고: user_robots 테이블과 users 테이블의 oil_balance, active_robot_id 필드는
-- 데이터 마이그레이션 확인 후 삭제 가능
-- DROP TABLE user_robots;
-- ALTER TABLE users DROP COLUMN oil_balance;
-- ALTER TABLE users DROP COLUMN active_robot_id;
