pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'
        ECR_REPO = 'my-repo'
        IMAGE_TAG = 'latest'
        SERVICE_NAME = 'llmops-medical-service1'
    }

    stages {
        stage('Clone GitHub Repo') {
            steps {
                script {
                    echo 'Cloning GitHub repo to Jenkins...'
                    checkout scmGit(branches: [[name: '*/main']], extensions: [], userRemoteConfigs: [[credentialsId: 'github-token', url: 'https://github.com/utkarshdeshmane/RAG-MEDICAL-CHATBOT.git']])
                }
            }
        }

        // stage('Build, Scan, and Push Docker Image to ECR') {
        //     steps {
        //         withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-token']]) {
        //             script {
        //                 def accountId = sh(script: "aws sts get-caller-identity --query Account --output text", returnStdout: true).trim()
        //                 def ecrUrl = "${accountId}.dkr.ecr.${env.AWS_REGION}.amazonaws.com/${env.ECR_REPO}"
        //                 def imageFullTag = "${ecrUrl}:${IMAGE_TAG}"

        //                 sh """
        //                 aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ecrUrl}
        //                 docker build -t ${env.ECR_REPO}:${IMAGE_TAG} .
        //                 trivy image --severity HIGH,CRITICAL --format json -o trivy-report.json ${env.ECR_REPO}:${IMAGE_TAG} || true
        //                 docker tag ${env.ECR_REPO}:${IMAGE_TAG} ${imageFullTag}
        //                 docker push ${imageFullTag}
        //                 """

        //                 archiveArtifacts artifacts: 'trivy-report.json', allowEmptyArchive: true
        //             }
        //         }
        //     }
        // }
        stage('Build, Scan, and Push Docker Image to ECR') {
    steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-token']]) {
            script {
                def accountId = sh(script: "aws sts get-caller-identity --query Account --output text", returnStdout: true).trim()
                def ecrUrl = "${accountId}.dkr.ecr.${env.AWS_REGION}.amazonaws.com"
                def fullRepo = "${ecrUrl}/${env.ECR_REPO}"
                def fullImageTag = "${fullRepo}:${IMAGE_TAG}"

                // 1. Ensure ECR repo exists
                sh """
                aws ecr describe-repositories --repository-name ${ECR_REPO} --region ${AWS_REGION} \
                || aws ecr create-repository --repository-name ${ECR_REPO} --region ${AWS_REGION}
                """

                // 2. Login to ECR
                sh """
                aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ecrUrl}
                """

                // 3. Build image
                sh """
                docker build -t ${ECR_REPO}:${IMAGE_TAG} .
                """

                // 4. Trivy scan (never fail pipeline)
                sh """
                trivy image --severity HIGH,CRITICAL --scanners vuln --timeout 10m \
                    --format json -o trivy-report.json ${ECR_REPO}:${IMAGE_TAG} || true
                """

                // 5. Tag + push to ECR
                sh """
                docker tag ${ECR_REPO}:${IMAGE_TAG} ${fullImageTag}
                docker push ${fullImageTag}
                """
            }

            archiveArtifacts artifacts: 'trivy-report.json', allowEmptyArchive: true
        }
    }
}

         stage('Deploy to AWS App Runner') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-token']]) {
                    script {
                        def accountId = sh(script: "aws sts get-caller-identity --query Account --output text", returnStdout: true).trim()
                        def ecrUrl = "${accountId}.dkr.ecr.${env.AWS_REGION}.amazonaws.com/${env.ECR_REPO}"
                        def imageFullTag = "${ecrUrl}:${IMAGE_TAG}"

                        echo "Triggering deployment to AWS App Runner..."

                        sh """
                        SERVICE_ARN=\$(aws apprunner list-services --query "ServiceSummaryList[?ServiceName=='${SERVICE_NAME}'].ServiceArn" --output text --region ${AWS_REGION})
                        echo "Found App Runner Service ARN: \$SERVICE_ARN"

                        aws apprunner start-deployment --service-arn \$SERVICE_ARN --region ${AWS_REGION}
                        """
                    }
                }
            }
        }
    }
}