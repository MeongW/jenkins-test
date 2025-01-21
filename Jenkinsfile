pipeline {
    agent any

    environment {
        // 환경변수 이름에 맞춰서 수정
        DISCORD_WEBHOOK_URL_DEV = "${env.TEST_DISCORD_WEBHOOK_URL_DEV}"
        DISCORD_WEBHOOK_URL_PROD = "${env.TEST_DISCORD_WEBHOOK_URL_PROD}"
        REGISTRY_CREDENTIAL = "${env.TEST_DOCKERHUB_CREDENTIAL}"
        SSH_CREDENTIAL_ID = "${env.TEST_SSH_CREDENTIAL}"
        GIT_URL = "${env.TEST_GIT_URL}"
        IMAGE_NAME = "${env.TEST_IMAGE_NAME}"
        CONTAINER_NAME_DEV = "${env.TEST_CONTAINER_NAME_DEV}"
        CONTAINER_NAME_PROD = "${env.TEST_CONTAINER_NAME_PROD}"
        SPRING_SERVER = "${env.TEST_SPRING_SERVER}"

        // 태그 설정
        TAG = "${env.GIT_BRANCH.tokenize('/').last()}-${env.BUILD_NUMBER}"
    }

    stages {
        stage('Clone') {
            steps {
                echo 'Cloning Repository'
                git url: "${env.GIT_URL}",
                    branch: "${env.GIT_BRANCH}",
                      credentialsId: 'github_personal_access_token'
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
                    sh '''
                        chmod +x ./gradlew
                        ./gradlew clean build
                    '''
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
                      dockerImage = docker.build("${env.IMAGE_NAME}:${env.TAG}")
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
                echo 'Pushing Docker Image'
                script {
                    docker.withRegistry('', env.REGISTRY_CREDENTIAL) {
                        dockerImage.push()
                    }
                }
            }
            post {
                failure {
                    error 'This pipeline stops here...'
                }
            }
        }
      
        stage('Remove Docker Image') {
            steps {
                echo 'Remove Docker Image'
                script {
                    docker.rmi(dockerImage)
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
                sshagent (credentials: [env.SSH_CREDENTIAL_ID]) {
                    // Docker 이미지 풀
                    sh "ssh -o StrictHostKeyChecking=no ${env.SPRING_SERVER} 'sudo docker pull ${env.IMAGE_NAME}:${env.TAG}'"
                    
                    // 컨테이너 ID 확인 후 삭제
                    sh """
                    ssh -o StrictHostKeyChecking=no ${env.SPRING_SERVER} '
                    CONTAINER_ID=\$(sudo docker ps -q --filter name=${env.SPRING_SERVER == 'prod' ? env.CONTAINER_NAME_PROD : env.CONTAINER_NAME_DEV})
                    if [ -n "\$CONTAINER_ID" ]; then
                        sudo docker rm -f \$CONTAINER_ID
                    fi
                    '
                    """
                    
                    // 환경에 맞는 포트 설정 (dev는 9090, prod는 9091)
                    def port = (env.SPRING_SERVER == 'prod') ? '9091' : '9090'
                    
                    // 환경에 맞는 컨테이너 이름 설정 (dev는 CONTAINER_NAME_DEV, prod는 CONTAINER_NAME_PROD)
                    def containerName = (env.SPRING_SERVER == 'prod') ? env.CONTAINER_NAME_PROD : env.CONTAINER_NAME_DEV
        
                    // Docker 컨테이너 실행
                    sh "ssh -o StrictHostKeyChecking=no ${env.SPRING_SERVER} 'sudo docker run -d --name ${containerName} -p ${port}:${port} ${env.IMAGE_NAME}:${env.TAG}'"
                }
            }
        }


    post {
        success {
            script {
                if (env.GIT_BRANCH == 'main') {
                    sendDiscordNotification("Main Branch Build Success", "The build for the main branch was successful: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})", env.DISCORD_WEBHOOK_URL_PROD)
                } else if (env.GIT_BRANCH == 'develop') {
                    sendDiscordNotification("Develop Branch Build Success", "The build for the develop branch was successful: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})", env.DISCORD_WEBHOOK_URL_DEV)
                }
            }
        }
        failure {
            script {
                if (env.GIT_BRANCH == 'main') {
                    sendDiscordNotification("Main Branch Build Failed", "The build for the main branch has failed: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})", env.DISCORD_WEBHOOK_URL_PROD)
                } else if (env.GIT_BRANCH == 'develop') {
                    sendDiscordNotification("Develop Branch Build Failed", "The build for the develop branch has failed: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})", env.DISCORD_WEBHOOK_URL_DEV)
                }
            }
        }
    }
}

// Discord 알림을 보내는 함수 정의
import groovy.json.JsonOutput

def sendDiscordNotification(title, message, webhookUrl) {
  discordSend description: """
  제목: ${currentBuild.displayName}
  결과: ${currentBuild.result}
  실행 시간: ${currentBuild.duration / 1000}s
  메시지: ${message}
  """, 
  link: env.BUILD_URL, result: currentBuild.currentResult, 
  title: "${env.JOB_NAME} : ${currentBuild.displayName}", 
  webhookURL: webhookUrl
}
