pipeline {
    agent any

    parameters {
        text(defaultValue: "latest", name: 'ImageTag', description: 'Define the Container Image Tag')
    }

    environment {
        VAULT_ADDR = 'https://vault.htoohtoo.cloud:8443'
        VAULT_BIN = "/usr/local/bin/vault"
        CONTAINER_REGISTRY = 'harbor.htoohtoo.cloud/hc-genai'
        JENKINS_TRUSTED_ENTITY_ROLE = credentials('trusted-entity-role-id') // Vault role credential
        JENKINS_TRUSTED_ENTITY_SECRET = credentials('trusted-entity-secret-id') // Vault secret credential
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

        stage('Fetch Registry Credentials') {
            steps {
                script {
                    def username = sh(
                        script: "${VAULT_BIN} kv get -field=username secret/container-registry",
                        returnStdout: true,
                        env: ["VAULT_TOKEN=${env.VAULT_TOKEN}"]
                    ).trim()

                    def password = sh(
                        script: "${VAULT_BIN} kv get -field=password secret/container-registry",
                        returnStdout: true,
                        env: ["VAULT_TOKEN=${env.VAULT_TOKEN}"]
                    ).trim()

                    env.CR_USERNAME = username
                    env.CR_PASSWORD = password
                }
            }
        }

        stage("Build, Tag and Push Docker Image") {
            steps {
                script {
                    sh """
                        # Set permissions properly to avoid conflicts
                        find ${env.WORKSPACE} -type d -exec chmod 755 {} +
                        find ${env.WORKSPACE} -type f -exec chmod 644 {} +
                        chown -R jenkins:jenkins ${env.WORKSPACE}

                        # Build Docker image
                        cd ${env.WORKSPACE}/todo-app
                        docker build -f Dockerfile -t ${CONTAINER_REGISTRY}/llm-obj-discovery:$BUILD_NUMBER .

                        # Docker registry login (Harbor)
                        echo '\${CR_PASSWORD}' | docker login ${CONTAINER_REGISTRY} -u '\${CR_USERNAME}' --password-stdin

                        # Push the image to the registry
                        docker push ${CONTAINER_REGISTRY}/llm-obj-discovery:$BUILD_NUMBER

                        # Tag and push the final version
                        docker tag ${CONTAINER_REGISTRY}/llm-obj-discovery:$BUILD_NUMBER ${CONTAINER_REGISTRY}/llm-obj-discovery:${params.ImageTag}
                        docker push ${CONTAINER_REGISTRY}/llm-obj-discovery:${params.ImageTag}
                    """
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
