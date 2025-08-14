# TodayUs Backend

Spring Boot 3 REST API backend for TodayUs application.

## Prerequisites

- Java 17
- PostgreSQL 15
- Docker (for database)

## Quick Start

1. Start PostgreSQL database:
   ```bash
   # From project root
   docker-compose up -d
   ```

2. Run the application:
   ```bash
   ./gradlew bootRun
   ```

3. The backend will be available at: `http://localhost:8080`

## Development Commands

```bash
# Build the application
./gradlew build

# Run the application
./gradlew bootRun

# Run tests
./gradlew test

# Clean build
./gradlew clean build
```

## Database Configuration

- **Database**: PostgreSQL 15
- **URL**: jdbc:postgresql://localhost:5432/todayus
- **Default User**: todayus
- **Default Password**: password

Use environment variables `DB_USERNAME` and `DB_PASSWORD` to override.

## API Documentation

Once running, the API will be available at:
- Base URL: `http://localhost:8080`
- Health check: `http://localhost:8080/actuator/health` (if actuator is enabled)