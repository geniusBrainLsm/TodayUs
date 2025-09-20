pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                // Git 저장소 클론
                git branch: 'main',
                    url: 'https://github.com/geniusBrainLsm/TodayUs.git'
            }
        }

        stage('Deploy Backend') {
            steps {
                // Jenkins workspace에서 실행
                sh '''
                    pwd
                    ls -la
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
            sh 'docker-compose logs backend || true'
        }
    }
}
