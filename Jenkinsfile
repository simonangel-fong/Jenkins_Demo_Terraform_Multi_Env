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
      steps {

      }
    }

    stage('Test') {
      steps {
        
      }
    }

    stage('Prod') {
      steps {
        
      }
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
