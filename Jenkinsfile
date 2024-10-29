pipeline {
    agent any

    parameters {
        text(defaultValue: "latest", name: 'ImageTag', description: 'Define the Container Image Tag')
    }

    environment {
        VAULT_ADDR = 'https://vault.htoohtoo.cloud:8443'
        VAULT_BIN = "/usr/local/bin/vault"
        CONTAINER_REGISTRY = 'harbor.htoohtoo.cloud'
        CONTAINER_PROJECT = 'hc-genai'
        JENKINS_TRUSTED_ENTITY_ROLE = credentials('trusted-entity-role-id') // Vault role credential
        JENKINS_TRUSTED_ENTITY_SECRET = credentials('trusted-entity-secret-id') // Vault secret credential
    }

    stages {
        stage('Checkout Code') {
            steps {
                script {
                    checkout scmGit(
                        branches: [[name: 'main']],
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
                    // Login to Vault using role_id and secret_id
                    def vaultToken = sh(
                        script: "${VAULT_BIN} write -field=token auth/approle/login role_id=${JENKINS_TRUSTED_ENTITY_ROLE} secret_id=${JENKINS_TRUSTED_ENTITY_SECRET}",
                        returnStdout: true
                    ).trim()
                    
                    // Export VAULT_TOKEN as environment variable for next stage "Retrieve and Use RoleID"
                    env.VAULT_TOKEN = vaultToken
                }
            }
        }

        stage('Retrieve Wrapped SecretID') {
            steps {
                script {
                    // Use VAULT_TOKEN to write and retrieve the wrapped secret ID
                    def wrappedSecretId = sh(
                        script: "VAULT_TOKEN=${env.VAULT_TOKEN} ${VAULT_BIN} write -wrap-ttl=100s -field=wrapping_token -f auth/approle/role/container-registry/secret-id",
                        returnStdout: true
                    ).trim()

                    // Store wrappedSecretId for further usage in pipeline
                    env.WRAPPED_SECRET_ID = wrappedSecretId
                }
            }
        }

        stage('Unwrap and Use SecretID') {
            steps {
                script {
                    // Unwrap to get the SecretID
                    def secretId = sh(
                        script: "${VAULT_BIN} unwrap -field=secret_id ${env.WRAPPED_SECRET_ID}",
                        returnStdout: true
                    ).trim()
                    
                    // Use the unwrapped SecretID as needed
                    env.SECRET_ID = secretId
                }
            }
        }

        stage('Retrieve RoleID') {
            steps {
                script {
                    // Read to get the RoleID
                    def roleId = sh(
                        script: "VAULT_TOKEN=${env.VAULT_TOKEN} ${VAULT_BIN} read -field=role_id auth/approle/role/container-registry/role-id",
                        returnStdout: true
                    ).trim()
                    
                    // Use the RoleID as needed
                    env.ROLE_ID = roleId
                }
            }
        }

       stage('Authenticate with Vault') {
            steps {
                script {
                    // Login to Vault with the RoleID and SecretID to retrieve the Vault token
                    def vaultToken = sh(
                        script: "${VAULT_BIN} write -field=token auth/approle/login role_id=${env.ROLE_ID} secret_id=${env.SECRET_ID}",
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

        stage('Login to Container Registry') {
            steps {
                script {
                    // Disable echo temporarily to mask credentials
                    sh """
                        # Docker registry login (Harbor)
                        set +x
                        echo '${env.CR_PASSWORD}' | docker login ${CONTAINER_REGISTRY} -u '${env.CR_USERNAME}' --password-stdin
                        set -x
                    """
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
                        chown -R root:root ${env.WORKSPACE}

                        # Build Docker image
                        cd ${env.WORKSPACE}/todo-app
                        docker build -f Dockerfile -t ${CONTAINER_REGISTRY}/${CONTAINER_PROJECT}/llm-obj-discovery:$BUILD_NUMBER .

                        # Push the image to the registry
                        docker push ${CONTAINER_REGISTRY}/${CONTAINER_PROJECT}/llm-obj-discovery:$BUILD_NUMBER

                        # Tag and push the final version
                        docker tag ${CONTAINER_REGISTRY}/${CONTAINER_PROJECT}/llm-obj-discovery:$BUILD_NUMBER ${CONTAINER_REGISTRY}/${CONTAINER_PROJECT}/llm-obj-discovery:${params.ImageTag}
                        docker images
                        docker push ${CONTAINER_REGISTRY}/${CONTAINER_PROJECT}/llm-obj-discovery:${params.ImageTag}
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
