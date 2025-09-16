#!/bin/bash

# TodayUs Docker 배포 스크립트

set -e

echo "🚀 Starting TodayUs deployment with Docker Compose..."

# Git pull로 최신 코드 가져오기
echo "📥 Pulling latest code from Git..."
git pull origin main

# Docker Compose로 전체 스택 배포
echo "🐳 Deploying with Docker Compose..."

# 기존 컨테이너들 정리 (Jenkins 제외)
docker-compose stop backend frontend || true

# 이미지 다시 빌드 (캐시 없이)
echo "🏗️  Building images..."
docker-compose build --no-cache backend frontend

# 서비스들 시작
docker-compose up -d

echo "⏳ Waiting for services to start..."
sleep 45

# 배포 상태 확인
echo "🔍 Checking deployment status..."

# Backend 헬스 체크
if curl -f http://localhost:8080/actuator/health > /dev/null 2>&1; then
    echo "✅ Backend is healthy"
else
    echo "❌ Backend health check failed"
    docker-compose logs backend
    exit 1
fi

# Frontend 확인
if curl -f http://localhost > /dev/null 2>&1; then
    echo "✅ Frontend is accessible"
else
    echo "⚠️  Frontend may not be accessible"
    docker-compose logs frontend
fi

# Jenkins 확인
if curl -f http://localhost:8081 > /dev/null 2>&1; then
    echo "✅ Jenkins is running"
else
    echo "⚠️  Jenkins may not be accessible"
fi

echo "🎉 Deployment completed successfully!"
echo ""
echo "📋 Service URLs:"
echo "   Frontend: http://localhost"
echo "   Backend API: http://localhost:8080"
echo "   Jenkins: http://localhost:8081"
echo "   Database: localhost:5432"
echo ""
echo "🐳 Running containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"