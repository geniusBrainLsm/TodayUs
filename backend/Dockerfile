# Spring Boot Dockerfile for Railway (Root Directory = backend)
FROM eclipse-temurin:17-jdk-alpine as build

# Install wget for downloading Gradle
RUN apk add --no-cache wget unzip

WORKDIR /app

# Copy all files
COPY . .

# Download and install Gradle directly
RUN wget https://services.gradle.org/distributions/gradle-8.5-bin.zip \
    && unzip gradle-8.5-bin.zip \
    && mv gradle-8.5 gradle \
    && rm gradle-8.5-bin.zip

# Set PATH to include Gradle
ENV PATH="/app/gradle/bin:${PATH}"

# Build application using Gradle directly
RUN gradle clean build -x test --no-daemon

# Runtime stage
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# Copy JAR file
COPY --from=build /app/build/libs/*.jar app.jar

# Expose port
EXPOSE 8080

# Run application
ENTRYPOINT ["java", "-jar", "app.jar"]