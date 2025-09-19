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
