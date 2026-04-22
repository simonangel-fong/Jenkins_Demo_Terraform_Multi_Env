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
        echo 'Dev'
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
    }
    success {
    }
    failure {
    }
  }
}
