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

                    # Stop existing backend container
                    docker stop todayus-backend || true
                    docker rm todayus-backend || true

                    # Build new backend image
                    docker build -t todayus-backend ./backend

                    # Run backend container
                    docker run -d \
                        --name todayus-backend \
                        --network todayus_default \
                        -p 8080:8080 \
                        -e DB_URL=jdbc:postgresql://todayus-postgres:5432/todayus \
                        -e DB_USERNAME=todayus \
                        -e DB_PASSWORD=1234 \
                        todayus-backend
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
            sh 'docker logs todayus-backend || echo "No backend container logs available"'
        }
    }
}