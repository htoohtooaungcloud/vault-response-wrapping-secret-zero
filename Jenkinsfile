pipeline {
    agent any
    parameters {
        text(defaultValue: "latest", name: 'ImageTag', description: 'Define the Container Image Tag')
    }
    environment {
        VAULT_ADDR = 'https://vault.htoohtoo.cloud:8443'
        VAULT_BIN = "/usr/local/bin/vault"
        JENKINS_TRUSTED_ENTITY_ROLE = credentials('trusted-entity-role-id')
        JENKINS_TRUSTED_ENTITY_SECRET = credentials('trusted-entity-secret-id')
        CONTAINER_REGISTRY = 'harbor.htoohtoo.cloud/hc-genai'
    }
    stages {
        stage('Checkout Code') {
            steps {
                sshagent(['jenkins-github']) {
                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: 'genai-dev']],
                        userRemoteConfigs: [[
                            credentialsId: 'jenkins-github',
                            url: 'git@github.com:htoohtooaungcloud/vault-response-wrapping-secret-zero.git'
                        ]]
                    ])
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

        stage('Retrieve Wrapped SecretID') {
            steps {
                script {
                    def wrappedSecretId = sh(
                        script: "VAULT_TOKEN=${env.VAULT_TOKEN} ${VAULT_BIN} write -wrap-ttl=100s -field=wrapping_token -f auth/approle/role/container-registry/secret-id",
                        returnStdout: true
                    ).trim()
                    env.WRAPPED_SECRET_ID = wrappedSecretId
                }
            }
        }

        stage('Unwrap and Use SecretID') {
            steps {
                script {
                    def secretId = sh(
                        script: "${VAULT_BIN} unwrap -field=secret_id ${env.WRAPPED_SECRET_ID}",
                        returnStdout: true
                    ).trim()
                    env.SECRET_ID = secretId
                }
            }
        }

        stage('Retrieve RoleID') {
            steps {
                script {
                    def roleId = sh(
                        script: "VAULT_TOKEN=${env.VAULT_TOKEN} ${VAULT_BIN} read -field=role_id auth/approle/role/container-registry/role-id",
                        returnStdout: true
                    ).trim()
                    env.ROLE_ID = roleId
                }
            }
        }

        stage('Authenticate with Vault') {
            steps {
                script {
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
                        def username = sh(
                            script: "${VAULT_BIN} kv get -field=username secret/container-registry",
                            returnStdout: true
                        ).trim()
                        def password = sh(
                            script: "${VAULT_BIN} kv get -field=password secret/container-registry",
                            returnStdout: true
                        ).trim()
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
                        cd $WORKSPACE
                        docker build -f todo-app/Dockerfile -t ${env.CONTAINER_REGISTRY}/llm-obj-discovery:$BUILD_NUMBER .
                        echo ${env.CR_PASSWORD} | docker login -u ${env.CR_USERNAME} --password-stdin
                        docker push ${env.CONTAINER_REGISTRY}/llm-obj-discovery:$BUILD_NUMBER
                        docker tag ${env.CONTAINER_REGISTRY}/llm-obj-discovery:$BUILD_NUMBER ${env.CONTAINER_REGISTRY}/llm-obj-discovery:${params.ImageTag}
                        docker push ${env.CONTAINER_REGISTRY}/llm-obj-discovery:${params.ImageTag}
                    """
                }
            }
        }
    }
}
