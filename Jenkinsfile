pipeline {
  agent {
    kubernetes {
      label 'agent-terraform'
      defaultContainer 'terraform'
    }
  }

  options {
    timestamps()
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '20'))
  }

  environment {
    AWS_REGION    = 'ca-central-1'

    TF_ROOT       = 'infra'
    TF_STATE_KEY  = 'jenkins-terraform/test/terraform.tfstate'
    TF_PLAN_FILE  = 'tfplan.binary'
    TF_PLAN_TXT   = 'tfplan.txt'
    TF_VAR_FILE   = 'envs/test/terraform.tfvars'
  }

  parameters {
    booleanParam(
      name: 'CONFIRM_TEST_DEPLOY',
      defaultValue: false,
      description: 'Check to confirm manual deployment to test'
    )
  }

  stages {

    // stage('Manual Guard') {
    //   steps {
    //     script {
    //       if (!params.CONFIRM_TEST_DEPLOY) {
    //         error("Pipeline aborted: enable CONFIRM_TEST_DEPLOY for manual promotion to test.")
    //       }
    //     }
    //   }
    // }

    // stage('Branch Guard') {
    //   steps {
    //     script {
    //       def branchName = env.BRANCH_NAME ?: sh(
    //         script: 'git rev-parse --abbrev-ref HEAD',
    //         returnStdout: true
    //       ).trim()

    //       echo "Detected branch: ${branchName}"

    //       if (branchName != 'master') {
    //         error("Pipeline aborted: only master branch is supported. Current branch: ${branchName}")
    //       }
    //     }
    //   }
    // }

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Format') {
      steps {
        dir("${env.TF_ROOT}") {
          echo "###############################"
          echo "Terraform fmt"
          echo "###############################"
          sh 'terraform fmt -recursive -check'
        }
      }
    }

    stage('Init') {
      steps {
        dir("${env.TF_ROOT}") {
          withCredentials([
            string(credentialsId: 'tf-state-bucket', variable: 'TF_STATE_BUCKET'),
            [
              $class: 'AmazonWebServicesCredentialsBinding',
              credentialsId: 'aws-creds'
            ]
          ]) {
            echo "###############################"
            echo "Terraform init"
            echo "###############################"
            sh '''
              terraform init \
                -input=false \
                -reconfigure \
                -backend-config="bucket=${TF_STATE_BUCKET}" \
                -backend-config="key=${TF_STATE_KEY}" \
                -backend-config="region=${AWS_REGION}" \
                -backend-config="encrypt=true"
            '''
          }
        }
      }
    }

    stage('Validate') {
      steps {
        dir("${env.TF_ROOT}") {
          echo "###############################"
          echo "Terraform validate"
          echo "###############################"
          sh 'terraform validate'
        }
      }
    }

    stage('Trivy Scan') {
      steps {
        container('trivy') {
          echo "###############################"
          echo "Trivy config scan"
          echo "###############################"
          sh '''
            trivy config \
              --severity HIGH,CRITICAL \
              --exit-code 1 \
              ${TF_ROOT}/
          '''
        }
      }
    }

    stage('Plan (test)') {
      steps {
        dir("${env.TF_ROOT}") {
          withCredentials([
            [
              $class: 'AmazonWebServicesCredentialsBinding',
              credentialsId: 'aws-creds'
            ]
          ]) {
            echo "###############################"
            echo "Terraform plan (test)"
            echo "###############################"
            sh '''
              terraform plan \
                -input=false \
                -var="env=${TF_VAR_ENV}"  \
                -out="${TF_PLAN_FILE}"

              terraform show -no-color "${TF_PLAN_FILE}" > "${TF_PLAN_TXT}"
            '''
          }
        }
      }
    }

    stage('Archive') {
      steps {
        echo "###############################"
        echo "Archive Artifacts"
        echo "###############################"

        archiveArtifacts(
          artifacts: "${env.TF_ROOT}/${env.TF_PLAN_FILE}, ${env.TF_ROOT}/${env.TF_PLAN_TXT}",
          fingerprint: true
        )
      }
    }

    stage('Apply (test)') {
      steps {
        dir("${env.TF_ROOT}") {
          withCredentials([
            [
              $class: 'AmazonWebServicesCredentialsBinding',
              credentialsId: 'aws-creds'
            ]
          ]) {
            echo "###############################"
            echo "Terraform apply (test)"
            echo "###############################"
            sh '''
              terraform apply -input=false "${TF_PLAN_FILE}"
            '''
          }
        }
      }
    }

    stage('Confirm') {
      steps {
        container('aws') {
          withCredentials([
            [
              $class: 'AmazonWebServicesCredentialsBinding',
              credentialsId: 'aws-creds'
            ]
          ]) {
            echo "###############################"
            echo "Confirm test VPC exists"
            echo "###############################"
            sh '''
              set -e

              VPC_ID=$(aws ec2 describe-vpcs \
                --region "${AWS_REGION}" \
                --filters "Name=tag:Environment,Values=dev" \
                --query 'Vpcs[0].VpcId' \
                --output text)

              if [ -z "${VPC_ID}" ] || [ "${VPC_ID}" = "None" ]; then
                echo "ERROR: No VPC found with tag Env=test"
                exit 1
              fi

              echo "Confirmed VPC exists: ${VPC_ID}"
            '''
          }
        }
      }
    }
  }

  post {
    always {
      echo "###############################"
      echo "Pipeline finished."
      echo "###############################"
    }
    success {
      emailext(
        to: "${env.MAIL_SMTP_USER}",
        subject: "${env.JOB_NAME} - Build #${env.BUILD_NUMBER} - SUCCESS",
        body: """<p>Job: <b>${env.JOB_NAME}</b> | Build: <b>#${env.BUILD_NUMBER}</b> | Status: <b>SUCCESS</b></p>
<p>Console: <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>""",
        mimeType: 'text/html'
      )
    }
    failure {
      emailext(
        to: "${env.MAIL_SMTP_USER}",
        subject: "${env.JOB_NAME} - Build #${env.BUILD_NUMBER} - FAILURE",
        body: """<p>Job: <b>${env.JOB_NAME}</b> | Build: <b>#${env.BUILD_NUMBER}</b> | Status: <b>FAILURE</b></p>
<p>Console: <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>""",
        mimeType: 'text/html'
      )
    }
  }
}