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
                    # 현재 디렉토리 확인
                    echo "📍 Current directory: $(pwd)"

                    # .env 파일을 /home/ubuntu/TodayUs에서 복사
                    echo "📋 Copying .env file from /home/ubuntu/TodayUs"
                    cp /home/ubuntu/TodayUs/.env . || {
                        echo "❌ ERROR: Failed to copy .env file from /home/ubuntu/TodayUs"
                        exit 1
                    }

                    # .env 파일 존재 확인
                    if [ ! -f .env ]; then
                        echo "❌ ERROR: .env file not found after copying"
                        exit 1
                    fi

                    # .env 파일 내용 확인 (보안을 위해 마스킹)
                    echo "✅ .env file found with $(wc -l < .env) lines"

                    # docker-compose.yml도 업데이트된 버전으로 복사
                    echo "📋 Copying docker-compose.yml from /home/ubuntu/TodayUs"
                    cp /home/ubuntu/TodayUs/docker-compose.yml . || {
                        echo "❌ ERROR: Failed to copy docker-compose.yml"
                        exit 1
                    }

                    # 파일 복사 확인
                    echo "📋 Files in workspace:"
                    ls -la .env docker-compose.yml

                    # 이전 컨테이너 정리
                    docker-compose down || true
                    docker container rm -f todayus-backend || true

                    # 이미지 제거하여 새로 빌드 강제
                    docker rmi todayus_backend:latest || true

                    # 백엔드 이미지 빌드 및 실행 (캐시 없이)
                    docker-compose build --no-cache backend
                    docker-compose up -d backend

                    # 컨테이너 상태 확인
                    sleep 10
                    docker ps | grep todayus-backend

                    # 환경변수 로드 확인
                    docker logs todayus-backend --tail=20 | grep -E "JWT|OpenAI|Configuration" || echo "✅ Environment loading check completed"
                '''
            }
        }
    }

    post {
        success {
            echo '🎉 Backend deployment successful!'
        }
        failure {
            echo '❌ Deployment failed!'
            sh '''
                echo "📋 Current directory contents:"
                ls -la
                echo "📋 Docker containers:"
                docker ps -a | grep todayus || true
                echo "📋 Docker logs (if container exists):"
                docker logs todayus-backend --tail=50 || true
            '''
        }
    }
}