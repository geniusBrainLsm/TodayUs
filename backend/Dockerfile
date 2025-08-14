# Simple Spring Boot Dockerfile for Railway
FROM eclipse-temurin:17-jdk-alpine as build

WORKDIR /app

# Copy gradle files
COPY gradle gradle
COPY gradlew gradlew.bat build.gradle settings.gradle ./

# Make gradlew executable
RUN chmod +x gradlew

# Download dependencies
RUN ./gradlew dependencies --no-daemon

# Copy source code
COPY src src

# Build application
RUN ./gradlew clean build -x test --no-daemon

# Runtime stage
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# Copy JAR file
COPY --from=build /app/build/libs/*.jar app.jar

# Expose port
EXPOSE 8080

# Run application
CMD ["java", "-jar", "app.jar"]