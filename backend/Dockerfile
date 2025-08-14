# Spring Boot Dockerfile for Railway (Root Directory = backend)
FROM eclipse-temurin:17-jdk-alpine as build

WORKDIR /app

# Copy all files
COPY . .

# Debug: List files to see what we have
RUN ls -la

# Make gradlew executable
RUN chmod +x gradlew

# Debug: Check gradlew and gradle files
RUN ls -la gradlew* gradle* build.gradle settings.gradle

# Set GRADLE_USER_HOME to avoid path issues
ENV GRADLE_USER_HOME=/app/.gradle

# Build application with explicit settings file
RUN ./gradlew clean build -x test --no-daemon --settings-file settings.gradle

# Runtime stage
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# Copy JAR file
COPY --from=build /app/build/libs/*.jar app.jar

# Expose port
EXPOSE 8080

# Run application
ENTRYPOINT ["java", "-jar", "app.jar"]