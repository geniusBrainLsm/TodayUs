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
                    cd /workspace
                    docker-compose stop backend || true
                    docker-compose build --no-cache backend
                    docker-compose up -d backend
                '''
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                    sleep 30
                    curl -f http://localhost:8080/actuator/health || exit 1
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
            sh 'cd /workspace && docker-compose logs backend'
        }
    }
}