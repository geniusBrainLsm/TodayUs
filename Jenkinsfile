pipeline {
    agent any

    environment {
        DOCKER_BUILDKIT = '1'
        COMPOSE_PROJECT_NAME = 'todayus'
    }

    stages {
        stage('Checkout') {
            steps {
                // Complete workspace cleanup
                sh 'rm -rf * .* || true'

                checkout scm

                // Verify checkout and show file structure
                sh '''
                    echo "=== Git status after checkout ==="
                    git status
                    echo "=== DiaryService.java exists? ==="
                    ls -la backend/src/main/java/com/todayus/service/DiaryService.java || echo "FILE NOT FOUND"
                    echo "=== Search for hasTodayDiary method ==="
                    grep -n "hasTodayDiary" backend/src/main/java/com/todayus/service/DiaryService.java || echo "METHOD NOT FOUND"
                '''

                echo 'Code checked out and verified successfully'
            }
        }

        stage('Install Dependencies') {
            steps {
                script {
                    sh '''
                        # Install Docker if not present
                        if ! command -v docker &> /dev/null; then
                            echo "Installing Docker..."
                            curl -fsSL https://get.docker.com -o get-docker.sh
                            sh get-docker.sh
                            rm get-docker.sh
                        fi

                        # Install Docker Compose if not present
                        if ! command -v docker-compose &> /dev/null; then
                            echo "Installing Docker Compose..."
                            curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                            chmod +x /usr/local/bin/docker-compose
                        fi

                        # Verify installations
                        docker --version
                        docker-compose --version
                    '''
                }
            }
        }

        stage('Build Backend') {
            steps {
                dir('backend') {
                    sh '''
                        echo "Building Spring Boot backend..."
                        chmod +x gradlew

                        # Force clean all caches and temporary files
                        rm -rf .gradle build
                        ./gradlew clean --no-daemon

                        # Build with verbose output for debugging
                        ./gradlew build -x test --no-daemon --info
                        echo "Backend build completed"
                    '''
                }
            }
        }

        stage('Build Docker Images') {
            steps {
                sh '''
                    echo "Building backend Docker image..."
                    docker build -t todayus/backend:latest ./backend
                    echo "Backend Docker image built successfully"
                '''
            }
        }

        stage('Deploy Backend') {
            steps {
                sh '''
                    echo "Stopping existing backend service..."
                    docker stop todayus-backend || true
                    docker rm todayus-backend || true

                    echo "Starting backend service with RDS connection..."
                    docker run -d \
                        --name todayus-backend \
                        -p 8080:8080 \
                        --restart unless-stopped \
                        todayus/backend:latest

                    echo "Backend deployed successfully with RDS"
                '''
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                    echo "Waiting for backend to start..."
                    sleep 30

                    echo "Checking backend health..."
                    timeout 60 bash -c 'until curl -f http://localhost:8080/actuator/health; do echo "Waiting for backend..."; sleep 5; done'

                    echo "Backend is healthy!"
                '''
            }
        }

        stage('Cleanup') {
            steps {
                sh '''
                    echo "Cleaning up unused Docker images..."
                    docker image prune -f
                    echo "Cleanup completed"
                '''
            }
        }
    }

    post {
        always {
            sh '''
                echo "=== Deployment Summary ==="
                docker ps --format "table {{.Names}}\\t{{.Status}}\\t{{.Ports}}"
                echo "=========================="
            '''
        }
        success {
            echo '🎉 Backend deployment successful!'
            sh '''
                echo "✅ Backend Status:"
                docker ps --filter name=todayus-backend
            '''
        }
        failure {
            echo '❌ Deployment failed!'
            sh '''
                echo "📋 Container logs for debugging:"
                docker logs --tail=50 todayus-backend || echo "No backend logs available"
            '''
        }
        cleanup {
            sh '''
                echo "🧹 Cleaning up workspace..."
                # Keep running containers but clean workspace
            '''
        }
    }
}