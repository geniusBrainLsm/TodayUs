-- 수동 마이그레이션: couples 테이블에 이미 oil_balance 컬럼이 추가되었지만 NOT NULL 제약조건 실패한 경우
-- 이 SQL을 서버 데이터베이스에서 직접 실행하세요

-- 1. 기존 컬럼에 기본값 설정
UPDATE couples SET oil_balance = 0 WHERE oil_balance IS NULL;
UPDATE couples SET active_robot_id = NULL WHERE active_robot_id IS NULL;

-- 2. NOT NULL 제약조건 추가
ALTER TABLE couples ALTER COLUMN oil_balance SET NOT NULL;
ALTER TABLE couples ALTER COLUMN oil_balance SET DEFAULT 0;

-- 3. couple_robots 테이블이 없으면 생성
CREATE TABLE IF NOT EXISTS couple_robots (
    id BIGSERIAL PRIMARY KEY,
    couple_id BIGINT NOT NULL,
    robot_id BIGINT NOT NULL,
    purchased_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_couple_robot UNIQUE (couple_id, robot_id)
);

-- 4. 인덱스 추가
CREATE INDEX IF NOT EXISTS idx_couple_robots_couple_id ON couple_robots(couple_id);
CREATE INDEX IF NOT EXISTS idx_couple_robots_robot_id ON couple_robots(robot_id);
CREATE INDEX IF NOT EXISTS idx_couples_active_robot_id ON couples(active_robot_id);

-- 5. 기존 user_robots 데이터를 couple_robots로 마이그레이션
INSERT INTO couple_robots (couple_id, robot_id, purchased_at)
SELECT DISTINCT c.id, ur.robot_id, ur.purchased_at
FROM user_robots ur
JOIN users u ON ur.user_id = u.id
JOIN couples c ON c.user1_id = u.id OR c.user2_id = u.id
ON CONFLICT (couple_id, robot_id) DO NOTHING;

-- 6. 기존 users의 active_robot을 couples로 복사
UPDATE couples c
SET active_robot_id = (
    SELECT u.active_robot_id
    FROM users u
    WHERE u.id = c.user1_id
    LIMIT 1
)
WHERE c.active_robot_id IS NULL;

-- 7. Flyway 메타데이터 테이블 업데이트 (V3 실패한 경우)
-- V3 마이그레이션 기록 삭제
DELETE FROM flyway_schema_history WHERE version = '3';

-- V4 마이그레이션 기록 추가
INSERT INTO flyway_schema_history (installed_rank, version, description, type, script, checksum, installed_by, installed_on, execution_time, success)
VALUES (
    (SELECT COALESCE(MAX(installed_rank), 0) + 1 FROM flyway_schema_history),
    '4',
    'add couple oil and robot',
    'SQL',
    'V4__add_couple_oil_and_robot.sql',
    0,
    'admin',
    NOW(),
    0,
    true
);

-- 완료 확인
SELECT 'Migration completed successfully!' as status;
