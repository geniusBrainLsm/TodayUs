# Multi-stage build for Spring Boot backend only
FROM openjdk:17-jdk-slim as build

# 작업 디렉토리 설정
WORKDIR /app

# Gradle 파일들 복사
COPY backend/gradle/ backend/gradle/
COPY backend/gradlew backend/gradlew.bat backend/build.gradle backend/settings.gradle ./backend/

# 의존성 다운로드 (캐시 최적화)
WORKDIR /app/backend
RUN chmod +x gradlew && ./gradlew dependencies --no-daemon

# 소스 코드 복사
WORKDIR /app
COPY backend/src/ backend/src/

# 빌드 실행
WORKDIR /app/backend
RUN ./gradlew clean build -x test --no-daemon

# Runtime stage
FROM openjdk:17-jdk-slim

WORKDIR /app

# 빌드된 JAR 파일 복사
COPY --from=build /app/backend/build/libs/*.jar app.jar

# 포트 노출
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

# 애플리케이션 실행
ENTRYPOINT ["java", "-jar", "/app/app.jar"]