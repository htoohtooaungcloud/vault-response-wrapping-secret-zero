pipeline {
    agent any
    parameters {
        text(defaultValue: "latest", name: 'ImageTag', description: 'Define the Container Image Tag')
    }
    environment {
        VAULT_ADDR = 'https://vault.htoohtoo.cloud:8443' // Replace with your Vault server address
        VAULT_BIN = "/usr/local/bin/vault" // Vault Binary Variable
        JENKINS_TRUSTED_ENTITY_ROLE = credentials('trusted-entity-role-id') // Credential stored in Jenkins environment
        JENKINS_TRUSTED_ENTITY_SECRET = credentials('trusted-entity-secret-id') // Credential stored in Jenkins environment
        CONTAINER_REGISTRY = 'harbor.htoohtoo.cloud/hc-genai'
    }
    stages {
        stage('Checkout Code') {
            steps {
                script {
                    // Perform Git checkout using scmGit
                    checkout scmGit(
                        branches: [[name: 'genai-dev']],
                        userRemoteConfigs: [[credentialsId:  'jenkins-github',
                            url: 'git@github.com:htoohtooaungcloud/vault-response-wrapping-secret-zero.git']]
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

        stage('Fetch Container Username and Password') {
            steps {
                script {
                    withEnv(["VAULT_TOKEN=${env.VAULT_TOKEN}"]) {
                        // Fetch secrets using the VAULT_TOKEN from the previous stage
                        def username = sh(
                            script: "${VAULT_BIN} kv get -field=username secret/container-registry",
                            returnStdout: true
                        ).trim()
                        
                        def password = sh(
                            script: "${VAULT_BIN} kv get -field=password secret/container-registry",
                            returnStdout: true
                        ).trim()
                        
                        // Store the fetched username and password in environment variables
                        env.CR_USERNAME = username
                        env.CR_PASSWORD = password
                    }
                }
            }
        }
        
        stage("Build, Tag and Push LLM Object Discovery Docker Image") {
            steps {
                script {
                    sh """
                        // Build Docker image
                        cd $WORKSPACE
                        sudo usermod -aG docker jenkins
                        docker build -f $WORKSPACE/todo-app/Dockerfile -t ${env.CONTAINER_REGISTRY}/llm-obj-discovery:$BUILD_NUMBER $WORKSPACE/.
                        // Log in to Docker registry
                        echo ${env.CR_PASSWORD} | docker login -u ${env.CR_USERNAME} --password-stdin
                        // Build Number Push
                        docker push ${env.CONTAINER_REGISTRY}/llm-obj-discovery:$BUILD_NUMBER
                        // Tag Docker Image
                        docker tag ${env.CONTAINER_REGISTRY}/llm-obj-discovery:$BUILD_NUMBER ${env.CONTAINER_REGISTRY}/llm-obj-discovery:${params.ImageTag}
                        // Push Ready Docker Image
                        docker push ${env.CONTAINER_REGISTRY}/llm-obj-discovery:${params.ImageTag}
                    """
                }
            }
        }
    }
}
