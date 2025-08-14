# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TodayUs is a full-stack application with:
- **Backend**: Spring Boot 3 with Java 17, PostgreSQL database
- **Frontend**: Flutter mobile/web application
- **Architecture**: REST API backend serving Flutter frontend

## Development Commands

### Backend (Spring Boot)
```bash
cd backend

# Build the application
./gradlew build

# Run the application
./gradlew bootRun

# Run tests
./gradlew test

# Clean build
./gradlew clean build
```

### Frontend (Flutter)
```bash
cd frontend

# Get dependencies
flutter pub get

# Run the app (development)
flutter run

# Build for release
flutter build apk        # Android
flutter build web        # Web
flutter build ios        # iOS (macOS only)

# Run tests
flutter test
```

### Database
```bash
# Start PostgreSQL with Docker
docker-compose up -d

# Stop database
docker-compose down
```

## Project Structure

### Backend (`backend/`)
- `src/main/java/com/todayus/TodayUsApplication.java` - Main Spring Boot application class
- Database configured for PostgreSQL on localhost:5432
- Default credentials: username=todayus, password=password
- Independent Gradle project with its own build.gradle

### Frontend (`frontend/`)
- Standard Flutter project structure
- Main entry point: `lib/main.dart`
- Dependencies managed via `pubspec.yaml`

## Database Configuration

- **Database**: PostgreSQL 15
- **URL**: jdbc:postgresql://localhost:5432/todayus
- **Default User**: todayus
- **Default Password**: password
- Use environment variables DB_USERNAME and DB_PASSWORD to override

## Development Workflow

1. Start PostgreSQL: `docker-compose up -d`
2. Run Spring Boot backend: `cd backend && ./gradlew bootRun`
3. Run Flutter frontend: `cd frontend && flutter run`
4. Backend runs on http://localhost:8080
5. Frontend connects to backend API