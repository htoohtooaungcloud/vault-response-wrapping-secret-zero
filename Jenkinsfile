pipeline {
    agent any  // Use any available Jenkins agent

    environment {
        // Use the Jenkins-provided GIT_BRANCH environment variable to set the tfvars file path
        BRANCH_NAME = "${env.GIT_BRANCH}".replaceFirst(/^origin\//, '')  // Strip 'origin/' prefix if present
        TFVARS_FILE = "${env.WORKSPACE}/../tf-vars/${BRANCH_NAME}.tfvars"
    }

    parameters {
        choice(
            name: 'TARGET_DIR',
            choices: ['tf-vault-setup', 'tf-aws-kms'],
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
                // Checkout the correct branch from the repository
                checkout([$class: 'GitSCM',
                    branches: [[name: "*/${BRANCH_NAME}"]],
                    userRemoteConfigs: [[
                        url: 'https://github.com/htoohtooaungcloud/vault-response-wrapping-secret-zero.git',
                        credentialsId: 'github-token'
                    ]]
                ])
            }
        }

        stage('Select Terraform Directory and Run Terraform') {
            steps {
                script {
                    switch (params.TARGET_DIR) {
                        case 'tf-aws-kms':
                            echo "Working in tf-aws-kms directory"
                            dir('tf-aws-kms') {
                                runTerraform(params.ACTION)
                            }
                            break

                        case 'tf-vault-setup':
                            echo "Working in tf-vault-setup directory"
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
    // Check if the .tfvars file exists before proceeding
    if (!fileExists(env.TFVARS_FILE)) {
        error "The variables file ${env.TFVARS_FILE} does not exist!"
    }

    switch (action) {
        case 'plan':
            echo "Running Terraform plan with var file ${env.TFVARS_FILE}..."
            sh 'terraform init'
            sh "terraform plan -var-file=${env.TFVARS_FILE} -out=tfplan"
            break

        case 'apply':
            echo "Running Terraform apply with var file ${env.TFVARS_FILE}..."
            sh 'terraform init'
            sh "terraform apply -var-file=${env.TFVARS_FILE} --auto-approve"
            break

        case 'destroy':
            if (params.CONFIRM_DESTROY) {
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
