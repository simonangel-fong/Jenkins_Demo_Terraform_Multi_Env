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

  triggers {
    pollSCM('H/2 * * * *')
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
        confirmVpc('dev', env.AWS_REGION)
      }
    }

    stage('Approve Test') {
      steps {
        timeout(time: 2, unit: 'MINUTES') {
          input message: 'Deploy to test?', ok: 'Approve'
        }
      }
    }

    stage('Deploy Test') {
      steps {
        terraformDeploy('test', env.TF_DIR, env.AWS_REGION, env.STATE_BUCKET_CRED)
        confirmVpc('test', env.AWS_REGION)
      }
    }

    stage('Approve Prod') {
      steps {
        timeout(time: 60, unit: 'MINUTES') {
          input message: 'Deploy to production?', ok: 'Approve'
        }
      }
    }

    stage('Deploy Prod') {
      steps {
        terraformDeploy('prod', env.TF_DIR, env.AWS_REGION, env.STATE_BUCKET_CRED)
        confirmVpc('prod', env.AWS_REGION)
      }
    }

  }

  post {
    success {
      withCredentials([
        usernamePassword(credentialsId: 'gmail_cred', usernameVariable: 'ADMIN_EMAIL', passwordVariable: 'ADMIN_PSW')
      ]) {
        emailext(
          to: "${ADMIN_EMAIL}",
          subject: "[Jenkins] SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
          body: """
            <p>Pipeline <b>${env.JOB_NAME} #${env.BUILD_NUMBER}</b> completed successfully.</p>
            <p>All environments (dev, test, prod) have been deployed.</p>
            <p><a href="${env.BUILD_URL}">View Build</a></p>
          """,
          mimeType: 'text/html'
        )
      }
    }
    failure {
      withCredentials([
        usernamePassword(credentialsId: 'gmail_cred', usernameVariable: 'ADMIN_EMAIL', passwordVariable: 'ADMIN_PSW')
      ]) {
        emailext(
          to: "${ADMIN_EMAIL}",
          subject: "[Jenkins] FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
          body: """
            <p>Pipeline <b>${env.JOB_NAME} #${env.BUILD_NUMBER}</b> has <b style="color:red">FAILED</b>.</p>
            <p><b>Failed stage:</b> ${env.STAGE_NAME}</p>
            <p><a href="${env.BUILD_URL}console">View Console Output</a></p>
            <br/>
            <b>Last 100 lines of build log:</b>
            <pre>${currentBuild.rawBuild.getLog(100).join('\n')}</pre>
          """,
          mimeType: 'text/html'
        )
      }
    }
    aborted {
      withCredentials([
        usernamePassword(credentialsId: 'gmail_cred', usernameVariable: 'ADMIN_EMAIL', passwordVariable: 'ADMIN_PSW')
      ]) {
        emailext(
          to: "${ADMIN_EMAIL}",
          subject: "[Jenkins] ABORTED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
          body: """
            <p>Pipeline <b>${env.JOB_NAME} #${env.BUILD_NUMBER}</b> was <b>ABORTED</b>.</p>
            <p>The production deployment approval was rejected or timed out.</p>
            <p><a href="${env.BUILD_URL}">View Build</a></p>
          """,
          mimeType: 'text/html'
        )
      }
    }
  }
}
