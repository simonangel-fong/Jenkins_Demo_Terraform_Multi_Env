@Library('jenkins-terraform-shared-lib') _

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
    AWS_REGION        = 'ca-central-1'
    TF_DIR            = 'infra'
    STATE_BUCKET_CRED = 'tf-state-bucket'
  }

  stages {

    stage('Deploy Dev') {
      steps {
        terraformDeploy('dev', env.TF_DIR, env.AWS_REGION, env.STATE_BUCKET_CRED)
      }
    }

    stage('Deploy Test') {
      steps {
        terraformDeploy('test', env.TF_DIR, env.AWS_REGION, env.STATE_BUCKET_CRED)
      }
    }

    stage('Approve Prod') {
      steps {
        input message: 'Deploy to production?', ok: 'Approve'
      }
    }

    stage('Deploy Prod') {
      steps {
        terraformDeploy('prod', env.TF_DIR, env.AWS_REGION, env.STATE_BUCKET_CRED)
      }
    }

  }
}
