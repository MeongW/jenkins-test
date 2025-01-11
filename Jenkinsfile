pipeline {
    agent any

    environment {
        // 환경변수 이름에 맞춰서 수정
        DISCORD_WEBHOOK_URL_DEV = "${env.A1GRADE_DISCORD_WEBHOOK_URL_DEV}"
        DISCORD_WEBHOOK_URL_PROD = "${env.A1GRADE_DISCORD_WEBHOOK_URL_PROD}"
        REGISTRY_CREDENTIAL = "${env.A1GRADE_DOCKERHUB_CREDENTIAL}"
        SSH_CREDENTIAL_ID = "${env.A1GRADE_SSH_CREDENTIAL}"
        GIT_URL = "${env.A1GRADE_GIT_URL}"
        IMAGENAME = "${env.A1GRADE_IMAGENAME}"
        SPRING_SERVER = "${env.A1GRADE_SPRING_SERVER}"

        // 태그 설정
        TAG = "${env.BRANCH_NAME}-${env.BUILD_NUMBER}"
    }

    stages {
        stage('Clone') {
            steps {
                echo 'Cloning Repository'
                git url: "${env.GIT_URL}",
                    branch: "${env.BRANCH_NAME}",
                    credentialsId: "${env.SSH_CREDENTIAL_ID}"
            }
            post {
                success {
                    echo 'Successfully Cloned Repository'
                }
                failure {
                    error 'This pipeline stops here...'
                }
            }
        }

        stage('Build Gradle') {
            steps {
                echo 'Building with Gradle'
                dir('.') {
                    sh './gradlew clean build'
                }
            }
            post {
                failure {
                    error 'This pipeline stops here...'
                }
            }
        }

        stage('Build Docker') {
            steps {
                echo 'Building Docker Image with Tag'
                script {
                    def imageNameWithTag = "${env.IMAGENAME}:${env.TAG}"
                    if (env.BRANCH_NAME == 'main') {
                        dockerImage = docker.build(imageNameWithTag)
                    } else if (env.BRANCH_NAME == 'develop') {
                        dockerImage = docker.build(imageNameWithTag)
                    } else {
                        error "Unknown branch ${env.BRANCH_NAME}, aborting!"
                    }
                }
            }
            post {
                failure {
                    error 'This pipeline stops here...'
                }
            }
        }

        stage('Push Docker') {
            steps {
                echo 'Pushing Docker Image with Tag'
                script {
                    def imageNameWithTag = "${env.IMAGENAME}:${env.TAG}"
                    docker.withRegistry('', env.REGISTRY_CREDENTIAL) {
                        dockerImage.push(imageNameWithTag)
                    }
                }
            }
            post {
                failure {
                    error 'This pipeline stops here...'
                }
            }
        }

        stage('Docker Run') {
            steps {
                echo 'Running Docker Container with Tag'
                sshagent(credentials: [env.SSH_CREDENTIAL_ID]) {
                    sh "ssh -o StrictHostKeyChecking=no ubuntu@${env.SPRING_SERVER} 'docker pull ${env.IMAGENAME}:${env.TAG}'"
                    sh "ssh -o StrictHostKeyChecking=no ubuntu@${env.SPRING_SERVER} 'docker ps -q --filter name=a1grade-springboot | grep -q . && docker rm -f \$(docker ps -aq --filter name=a1grade-springboot)'"
                    sh "ssh -o StrictHostKeyChecking=no ubuntu@${env.SPRING_SERVER} 'docker run -d --name a1grade-springboot -p 8080:8080 ${env.IMAGENAME}:${env.TAG}'"
                }
            }
        }
    }

    post {
        success {
            script {
                if (env.BRANCH_NAME == 'main') {
                    sendDiscordNotification("Main Branch Build Success", "The build for the main branch was successful: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})", env.DISCORD_WEBHOOK_URL_PROD)
                } else if (env.BRANCH_NAME == 'develop') {
                    sendDiscordNotification("Develop Branch Build Success", "The build for the develop branch was successful: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})", env.DISCORD_WEBHOOK_URL_DEV)
                }
            }
        }
        failure {
            script {
                if (env.BRANCH_NAME == 'main') {
                    sendDiscordNotification("Main Branch Build Failed", "The build for the main branch has failed: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})", env.DISCORD_WEBHOOK_URL_PROD)
                } else if (env.BRANCH_NAME == 'develop') {
                    sendDiscordNotification("Develop Branch Build Failed", "The build for the develop branch has failed: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})", env.DISCORD_WEBHOOK_URL_DEV)
                }
            }
        }
    }
}

// Discord 알림을 보내는 함수 정의
def sendDiscordNotification(title, message, webhookUrl) {
    sh """
        curl -X POST -H "Content-Type: application/json" \
        -d '{
            "embeds": [{
                "title": "${title}",
                "description": "${message}",
                "color": 3066993
            }]}'
        ${webhookUrl}
    """
}
