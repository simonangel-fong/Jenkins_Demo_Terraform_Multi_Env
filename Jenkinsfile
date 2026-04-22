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

    stage('Dev: Fmt') {
      steps {
        container('terraform') {
          dir("${env.TF_DIR}") {
            sh 'terraform fmt -recursive -check'
          }
        }
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
