pipeline {
    agent any  // Use any available Jenkins agent

    environment {
        // Use the current branch name to dynamically set the path to the .tfvars file
        TFVARS_FILE = "${JENKINS_HOME}/workspace/${WORKSPACE}/../tf-vars/${BRANCH_NAME}.tfvars" 
    }

    parameters {
        choice(
            name: 'TARGET_DIR',
            choices: ['tf-aws-kms', 'tf-vault-setup'],
            description: 'Select the directory to run the Terraform commands.'
        )
        choice(
            name: 'ACTION',
            choices: ['plan', 'apply', 'destroy'],
            description: 'Select the Terraform action to perform.'
        )
        booleanParam(
            name: 'CONFIRM_DESTROY',
            defaultValue: false,
            description: 'Confirm if you want to proceed with destroy (only used for "destroy" action).'
        )
    }

    stages {
        stage('Checkout Code') {
            steps {
                script {
                    checkout scmGit(
                        branches: [[name: 'tf-pipeline']],
                        userRemoteConfigs: [[
                            credentialsId: 'github-token',
                            url: 'https://github.com/htoohtooaungcloud/vault-response-wrapping-secret-zero.git'
                        ]]
                    )
                }
            }
        }

        stage('Select Directory and Run Terraform') {
            steps {
                script {
                    switch (params.TARGET_DIR) {
                        case 'tf-aws-kms':
                            echo 'Working in tf-aws-kms directory'
                            dir('tf-aws-kms') {
                                runTerraform(params.ACTION)
                            }
                            break

                        case 'tf-vault-setup':
                            echo 'Working in tf-vault-setup directory'
                            dir('tf-vault-setup') {
                                runTerraform(params.ACTION)
                            }
                            break

                        default:
                            error "Invalid directory: ${params.TARGET_DIR}. Use 'tf-aws-kms' or 'tf-vault-setup'."
                    }
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline completed.'
        }
    }
}

def runTerraform(action) {
    switch (action) {
        case 'plan':
            echo "Running Terraform plan with var file ${env.TFVARS_FILE}..."
            sh 'terraform init'
            sh "terraform plan -var-file=${env.TFVARS_FILE} -out=tfplan"
            break

        case 'apply':
            echo "Running Terraform apply with var file ${env.TFVARS_FILE}..."
            sh 'terraform init'
            sh "terraform apply -var-file=${env.TFVARS_FILE} --auto-approve tfplan"
            break

        case 'destroy':
            if (params.CONFIRM_DESTROY) {
                input message: 'Are you sure you want to destroy the resources?', ok: 'Yes'
                echo "Running Terraform destroy with var file ${env.TFVARS_FILE}..."
                sh 'terraform init'
                sh "terraform destroy -var-file=${env.TFVARS_FILE} --auto-approve"
            } else {
                echo 'Destroy action was not confirmed. Skipping destroy.'
            }
            break

        default:
            error "Invalid action: ${action}. Use 'plan', 'apply', or 'destroy'."
    }
}
