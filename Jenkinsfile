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
                    # 이전 컨테이너 정리
                    docker-compose down || true
                    docker container rm -f todayus-backend || true

                    # 백엔드 이미지 빌드 및 실행
                    docker-compose build --no-cache backend
                    docker-compose up -d backend
                '''
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                    sleep 20
                    # actuator health 확인
                    curl -f http://localhost:8080/actuator/health || curl -f http://localhost:8080/ || exit 1
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
            sh 'docker-compose logs backend'
        }
    }
}
