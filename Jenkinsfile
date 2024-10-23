pipeline {
    agent any

    parameters {
        text(defaultValue: "latest", name: 'ImageTag', description: 'Define the Container Image Tag')
    }

    environment {
        VAULT_ADDR = 'https://vault.htoohtoo.cloud:8443'
        VAULT_BIN = "/usr/local/bin/vault"
        CONTAINER_REGISTRY = 'harbor.htoohtoo.cloud/hc-genai'
    }

    stages {
        stage('Checkout Code') {
            steps {
                script {
                    checkout scmGit(
                        branches: [[name: 'genai-dev']],
                        userRemoteConfigs: [[
                            credentialsId: 'github-token',
                            url: 'https://github.com/htoohtooaungcloud/vault-response-wrapping-secret-zero.git'
                        ]]
                    )
                }
            }
        }

        stage('Login to Vault and Retrieve Trust-Entity Token') {
            steps {
                script {
                    def vaultToken = sh(
                        script: "${VAULT_BIN} write -field=token auth/approle/login role_id=${JENKINS_TRUSTED_ENTITY_ROLE} secret_id=${JENKINS_TRUSTED_ENTITY_SECRET}",
                        returnStdout: true
                    ).trim()
                    env.VAULT_TOKEN = vaultToken
                }
            }
        }

        stage('Fetch Container Registry Credentials') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'container-registry-credentials',
                    usernameVariable: 'CR_USERNAME',
                    passwordVariable: 'CR_PASSWORD'
                )]) {
                    script {
                        echo 'Fetched container registry credentials.'
                    }
                }
            }
        }

        stage('Build, Tag, and Push Docker Image') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'container-registry-credentials',
                    usernameVariable: 'CR_USERNAME',
                    passwordVariable: 'CR_PASSWORD'
                )]) {
                    script {
                        sh """
                            # Ensure correct permissions for files and directories
                            find ${env.WORKSPACE} -type d -exec chmod 755 {} +
                            find ${env.WORKSPACE} -type f -exec chmod 644 {} +

                            # Navigate to the Docker build context
                            cd ${env.WORKSPACE}/todo-app

                            # Build the Docker image
                            docker build -f Dockerfile -t ${CONTAINER_REGISTRY}/llm-obj-discovery:$BUILD_NUMBER .

                            # Log in to the Docker registry
                            echo "$CR_PASSWORD" | docker login $CONTAINER_REGISTRY -u "$CR_USERNAME" --password-stdin

                            # Push the built image to the registry
                            docker push ${CONTAINER_REGISTRY}/llm-obj-discovery:$BUILD_NUMBER

                            # Tag the image and push the tagged version
                            docker tag ${CONTAINER_REGISTRY}/llm-obj-discovery:$BUILD_NUMBER ${CONTAINER_REGISTRY}/llm-obj-discovery:${params.ImageTag}
                            docker push ${CONTAINER_REGISTRY}/llm-obj-discovery:${params.ImageTag}
                        """
                    }
                }
            }
        }
    }
    
    post {
        always {
            echo 'Pipeline execution completed.'
        }
    }
}
