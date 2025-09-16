pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                    chmod +x scripts/deploy.sh
                    ./scripts/deploy.sh
                '''
            }
        }
    }

    post {
        success {
            echo '🎉 Full stack deployment successful!'
        }
        failure {
            echo '❌ Deployment failed!'
            sh 'docker-compose logs'
        }
    }
}