# Spring Boot Dockerfile for Railway (Root Directory = backend)
FROM eclipse-temurin:17-jdk-alpine as build

WORKDIR /app

# Copy all files (Railway is already in backend directory)
COPY . .

# Make gradlew executable
RUN chmod +x gradlew

# Build application
RUN ./gradlew clean build -x test --no-daemon

# Runtime stage
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# Copy JAR file
COPY --from=build /app/build/libs/*.jar app.jar

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1

# Run application
ENTRYPOINT ["java", "-jar", "app.jar"]