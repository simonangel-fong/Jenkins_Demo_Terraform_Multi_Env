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
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Dev') {
    }

    stage('Test') {
    }

      stage('Prod') {
    }
  }

  post {
    always {
    }
    success {
    }
    failure {
    }
  }
}
