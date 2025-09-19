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
                    git pull origin main
                    docker-compose down || true
                    docker container rm -f todayus-backend || true
                    docker-compose build --no-cache backend
                    docker-compose up -d backend
                '''
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                    sleep 20
                    # Try actuator health first, if fails try basic health endpoint
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
