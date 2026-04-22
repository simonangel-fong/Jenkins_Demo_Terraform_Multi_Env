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
    AWS_REGION = 'ca-central-1'
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    // ── Dev ───────────────────────────────────────────────────────────────

    stage('Dev: Deploy') {
      steps {
        withCredentials([
          string(credentialsId: 'tf-state-bucket', variable: 'TF_STATE_BUCKET'),
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']
        ]) {
          sh 'chmod +x jenkins/script/deploy.sh'
          sh 'jenkins/script/deploy.sh dev'
        }
      }
      post {
        success {
          archiveArtifacts(
            artifacts: 'infra/tfplan.binary, infra/tfplan.txt',
            fingerprint: true
          )
        }
      }
    }

    stage('Dev: Test') {
      steps {
        container('aws') {
          withCredentials([
            [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']
          ]) {
            sh 'chmod +x jenkins/script/test.sh'
            sh 'jenkins/script/test.sh dev'
          }
        }
      }
    }

    // ── Test ──────────────────────────────────────────────────────────────

    stage('Test: Deploy') {
      steps {
        withCredentials([
          string(credentialsId: 'tf-state-bucket', variable: 'TF_STATE_BUCKET'),
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']
        ]) {
          sh 'jenkins/script/deploy.sh test'
        }
      }
      post {
        success {
          archiveArtifacts(
            artifacts: 'infra/tfplan.binary, infra/tfplan.txt',
            fingerprint: true
          )
        }
      }
    }

    stage('Test: Test') {
      steps {
        container('aws') {
          withCredentials([
            [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']
          ]) {
            sh 'jenkins/script/test.sh test'
          }
        }
      }
    }

    // ── Prod ──────────────────────────────────────────────────────────────

    stage('Prod: Approval') {
      steps {
        timeout(time: 30, unit: 'MINUTES') {
          input message: 'Deploy to prod?', ok: 'Approve'
        }
      }
    }

    stage('Prod: Deploy') {
      steps {
        withCredentials([
          string(credentialsId: 'tf-state-bucket', variable: 'TF_STATE_BUCKET'),
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']
        ]) {
          sh 'jenkins/script/deploy.sh prod'
        }
      }
      post {
        success {
          archiveArtifacts(
            artifacts: 'infra/tfplan.binary, infra/tfplan.txt',
            fingerprint: true
          )
        }
      }
    }

  }

  post {
    always {
      echo "Pipeline finished: ${currentBuild.currentResult}"
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
