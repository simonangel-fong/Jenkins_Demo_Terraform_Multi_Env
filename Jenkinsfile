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
    ADMIN_EMAIL       = credentials('gmail_cred_USR')
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

  post {
    success {
      emailext(
        to: "${env.ADMIN_EMAIL_USR}",
        subject: "[Jenkins] SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
        body: """
          <p>Pipeline <b>${env.JOB_NAME} #${env.BUILD_NUMBER}</b> completed successfully.</p>
          <p>All environments (dev, test, prod) have been deployed.</p>
          <p><a href="${env.BUILD_URL}">View Build</a></p>
        """,
        mimeType: 'text/html'
      )
    }
    failure {
      emailext(
        to: "${env.ADMIN_EMAIL_USR}",
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
    aborted {
      emailext(
        to: "${env.ADMIN_EMAIL_USR}",
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
