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
                    # 올바른 디렉토리로 이동 (서버의 실제 프로젝트 디렉토리)
                    cd /home/ubuntu/TodayUs

                    # 최신 코드 가져오기
                    git pull origin main

                    # .env 파일 존재 확인
                    if [ ! -f .env ]; then
                        echo "ERROR: .env file not found in /home/ubuntu/TodayUs"
                        exit 1
                    fi

                    # .env 파일 내용 확인 (보안을 위해 마스킹)
                    echo "📋 .env file found with $(wc -l < .env) lines"

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
                    docker logs todayus-backend --tail=20 | grep -E "JWT|OpenAI|Configuration" || echo "Checking environment..."
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
                cd /home/ubuntu/TodayUs
                docker-compose logs backend --tail=50
            '''
        }
    }
}