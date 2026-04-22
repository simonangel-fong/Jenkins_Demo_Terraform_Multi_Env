pipeline {
  agent {
    kubernetes {
      inheritFrom 'agent-terraform'
      defaultContainer 'terraform'
    }
  }

  options {
    timestamps()
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '20'))
  }

  environment {
    AWS_REGION = 'ca-central-1'
    TF_DIR     = 'infra'
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Dev') {
      stages {

        stage('Dev: Fmt') {
          steps {
            container('terraform') {
              sh 'terraform -chdir=${TF_DIR} fmt -recursive -check'
            }
          }
        }

        // stage('Dev: Init') {
        //   steps {
        //     container('terraform') {
        //       sh 'terraform -chdir=${TF_DIR} init'
        //     }
        //   }
        // }

        // stage('Dev: Validate') {
        //   steps {
        //     container('terraform') {
        //       sh 'terraform -chdir=${TF_DIR} validate'
        //     }
        //   }
        }

        // stage('Dev: Trivy Scan') {
        //   steps {
        //     container('trivy') {
        //       sh 'trivy config ${TF_DIR}'
        //     }
        //   }
        // }

        // stage('Dev: Plan') {
        //   steps {
        //     container('terraform') {
        //       sh 'terraform -chdir=${TF_DIR} plan -out=tfplan'
        //     }
        //   }
        //   post {
        //     always {
        //       archiveArtifacts artifacts: "${TF_DIR}/tfplan", allowEmptyArchive: true
        //     }
        //   }
        // }

        // stage('Dev: Apply') {
        //   steps {
        //     container('terraform') {
        //       sh 'terraform -chdir=${TF_DIR} apply -auto-approve tfplan'
        //     }
        //   }
        // }

        // stage('Dev: Verify') {
        //   steps {
        //     container('aws') {
        //       sh 'aws ec2 describe-vpcs --region ${AWS_REGION}'
        //     }
        //   }
        // }

      }
    }

    stage('Test') {
      steps {
        echo 'Test'
      }
    }

    stage('Prod') {
      steps {
        echo 'Prod'
      }
    }
  }

  post {
    always {
      echo 'always'
    }
    success {
      echo 'success'
    }
    failure {
      echo 'failure'
    }
  }
}
