@Library('terraformDeploy') _

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
    AWS_REGION   = 'ca-central-1'
    TF_DIR       = 'infra'
    TF_VAR_env   = 'dev'
    TF_STATE_KEY = "jenkins-terraform/${TF_VAR_env}/terraform.tfstate"
  }

  stages {

    stage('Fmt') {
      steps {
        container('terraform') {
          sh 'terraform -chdir=${TF_DIR} fmt -recursive -check'
        }
      }
    }

    stage('Init') {
      steps {
        container('terraform') {
          withCredentials([
            [$class: 'AmazonWebServicesCredentialsBinding',
             credentialsId: 'aws-creds',
             accessKeyVariable: 'AWS_ACCESS_KEY_ID',
             secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'],
            string(credentialsId: 'tf-state-bucket', variable: 'TF_STATE_BUCKET')
          ]) {
            sh '''
              terraform -chdir=${TF_DIR} init \
                -backend-config="bucket=${TF_STATE_BUCKET}" \
                -backend-config="key=${TF_STATE_KEY}" \
                -backend-config="region=${AWS_REGION}"
            '''
          }
        }
      }
    }

    stage('Validate') {
      steps {
        container('terraform') {
          sh 'terraform -chdir=${TF_DIR} validate'
        }
      }
    }

    stage('Scan') {
      steps {
        container('trivy') {
          sh 'trivy config ${TF_DIR}'
        }
      }
    }

    stage('Apply') {
      steps {
        container('terraform') {
          withCredentials([
            [$class: 'AmazonWebServicesCredentialsBinding',
             credentialsId: 'aws-creds',
             accessKeyVariable: 'AWS_ACCESS_KEY_ID',
             secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']
          ]) {
            sh 'terraform -chdir=${TF_DIR} apply -auto-approve tfplan'
          }
        }
      }
    }
  }
}
