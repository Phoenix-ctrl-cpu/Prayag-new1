pipeline {
    agent { label 'prayagcloud' }
    tools {
        jdk 'Java17'
        maven 'Maven3'
    }

    environment {
        	APP_NAME = "prayag-new1-pipeline"
            RELEASE = "1.0.0"
            DOCKER_USER = "prayag8tiwari"
            DOCKER_PASS = 'dockerhub'
            IMAGE_NAME = "${DOCKER_USER}" + "/" + "${APP_NAME}"
            IMAGE_TAG = "${RELEASE}-${BUILD_NUMBER}"
    }
    stages{
        stage("Cleanup Workspace"){
                steps {
                cleanWs()
                }
        }

        stage("Checkout from SCM"){
                steps {
                    git branch: 'main', credentialsId: 'github', url: 'https://github.com/Phoenix-ctrl-cpu/Prayag-new1'
                }
        }

        stage("Build Application"){
            steps {
                sh "mvn clean package"
            }

       }

       stage("Test Application"){
           steps {
                 sh "mvn test"
           }
       }
       stage("Build & Push Docker Image") {
            steps {
                script {
                    docker.withRegistry('',DOCKER_PASS) {
                        docker_image = docker.build "${IMAGE_NAME}"
                    }

                    docker.withRegistry('',DOCKER_PASS) {
                        docker_image.push("${IMAGE_TAG}")
                        docker_image.push('latest')
                    }
                }
            }
       }

       stage("Deploy to Staging") {
            when {
                branch 'main'
            }
            steps {
                script {
                    // Deploy to staging environment using Docker Compose
                    sh """
                        chmod +x scripts/deploy-docker-compose.sh
                        ./scripts/deploy-docker-compose.sh staging ${IMAGE_TAG}
                    """
                }
            }
       }

       stage("Health Check") {
            when {
                branch 'main'
            }
            steps {
                script {
                    // Wait for application to be ready
                    sh "sleep 30"
                    
                    // Perform health check
                    sh """
                        chmod +x scripts/health-check.sh
                        ./scripts/health-check.sh http://localhost:8080 60
                    """
                }
            }
       }

       stage("Deploy to Production") {
            when {
                branch 'main'
                // Add approval step for production deployment
                input message: 'Deploy to Production?', ok: 'Deploy'
            }
            steps {
                script {
                    // Deploy to production using Kubernetes
                    sh """
                        chmod +x scripts/deploy-k8s.sh
                        ./scripts/deploy-k8s.sh production ${IMAGE_TAG}
                    """
                }
            }
       }

       stage("Post-Deployment Health Check") {
            when {
                branch 'main'
            }
            steps {
                script {
                    // Wait for production deployment to be ready
                    sh "sleep 60"
                    
                    // Perform production health check
                    sh """
                        chmod +x scripts/health-check.sh
                        ./scripts/health-check.sh http://prayag-app.example.com 120
                    """
                }
            }
       }
   }

   post {
       always {
           // Clean up workspace
           cleanWs()
       }
       success {
           echo '🎉 Pipeline completed successfully!'
           // Send success notification (configure as needed)
       }
       failure {
           echo '💥 Pipeline failed!'
           // Send failure notification (configure as needed)
       }
   }
}
