pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Deploy Backend') {
            steps {
                sh '''
                    set -e  # Exit on any error

                    echo "📍 Current directory: $(pwd)"
                    echo "📍 Git branch: $(git branch --show-current)"
                    echo "📍 Git commit: $(git log -1 --oneline)"

                    # .env 파일을 /home/ubuntu/TodayUs에서 복사
                    echo "📋 Copying .env file from /home/ubuntu/TodayUs"
                    cp /home/ubuntu/TodayUs/.env . || {
                        echo "❌ ERROR: Failed to copy .env file"
                        exit 1
                    }

                    # .env 파일 확인
                    if [ ! -f .env ]; then
                        echo "❌ ERROR: .env file not found"
                        exit 1
                    fi
                    echo "✅ .env file found with $(wc -l < .env) lines"

                    # docker-compose.yml 확인 (git에서 가져온 파일 사용)
                    if [ ! -f docker-compose.yml ]; then
                        echo "❌ ERROR: docker-compose.yml not found"
                        exit 1
                    fi
                    echo "✅ docker-compose.yml found"

                    # 이전 컨테이너 정리
                    echo "🧹 Cleaning up old containers..."
                    docker-compose down 2>/dev/null || true
                    docker container rm -f todayus-backend 2>/dev/null || true

                    # 이전 이미지 제거
                    echo "🗑️  Removing old images..."
                    docker rmi todayus_backend:latest 2>/dev/null || true
                    docker image prune -f

                    # 백엔드 빌드 및 실행
                    echo "🔨 Building backend..."
                    docker-compose build --no-cache backend

                    echo "🚀 Starting backend..."
                    docker-compose up -d backend

                    # 컨테이너 시작 대기
                    echo "⏳ Waiting for container to start..."
                    sleep 15

                    # 컨테이너 상태 확인
                    if ! docker ps | grep -q todayus-backend; then
                        echo "❌ ERROR: Container failed to start"
                        docker logs todayus-backend --tail=50 || true
                        exit 1
                    fi

                    echo "✅ Container is running"
                    docker ps | grep todayus-backend

                    # 환경변수 로드 확인
                    echo "🔍 Checking environment variables..."
                    docker exec todayus-backend env | grep -E "^(JWT_SECRET|OPENAI_API_KEY|AWS_ACCESS_KEY_ID)=" | sed "s/=.*/=****/" || true

                    # 애플리케이션 로그 확인
                    echo "📋 Recent application logs:"
                    docker logs todayus-backend --tail=30 | grep -E "Started TodayUsApplication|Configuration" || echo "(No configuration logs yet)"

                    echo "🎉 Deployment completed successfully!"
                '''
            }
        }
    }

    post {
        success {
            echo '✅ Backend deployment successful!'
        }
        failure {
            echo '❌ Deployment failed!'
            sh '''
                echo "📋 Current directory: $(pwd)"
                echo "📋 Directory contents:"
                ls -la
                echo "📋 Docker containers:"
                docker ps -a | grep todayus || true
                echo "📋 Docker logs:"
                docker logs todayus-backend --tail=100 || true
            '''
        }
    }
}
