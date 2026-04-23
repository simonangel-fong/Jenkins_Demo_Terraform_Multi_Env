def call(String env, String tfDir, String awsRegion, String stateBucketCredId) {
  def stateKey = "jenkins-terraform/${env}/terraform.tfstate"

  stage("${env}: Fmt") {
    container('terraform') {
      sh "terraform -chdir=${tfDir} fmt -recursive -check"
    }
  }

  stage("${env}: Init") {
    container('terraform') {
      withCredentials([
        [$class: 'AmazonWebServicesCredentialsBinding',
         credentialsId: 'aws-creds',
         accessKeyVariable: 'AWS_ACCESS_KEY_ID',
         secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'],
        string(credentialsId: stateBucketCredId, variable: 'TF_STATE_BUCKET')
      ]) {
        sh """
          terraform -chdir=${tfDir} init \
            -backend-config="bucket=\${TF_STATE_BUCKET}" \
            -backend-config="key=${stateKey}" \
            -backend-config="region=${awsRegion}" \
            -reconfigure
        """
      }
    }
  }

  stage("${env}: Validate") {
    container('terraform') {
      sh "terraform -chdir=${tfDir} validate"
    }
  }

  stage("${env}: Scan") {
    container('trivy') {
      sh "trivy config ${tfDir}"
    }
  }

  stage("${env}: Plan") {
    container('terraform') {
      withCredentials([
        [$class: 'AmazonWebServicesCredentialsBinding',
         credentialsId: 'aws-creds',
         accessKeyVariable: 'AWS_ACCESS_KEY_ID',
         secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']
      ]) {
        sh """
          terraform -chdir=${tfDir} plan -var="env=${env}" -out=tfplan
          terraform -chdir=${tfDir} show -no-color tfplan > ${tfDir}/tfplan.txt
        """
      }
    }
    archiveArtifacts artifacts: "${tfDir}/tfplan, ${tfDir}/tfplan.txt", fingerprint: true
  }

  stage("${env}: Apply") {
    container('terraform') {
      withCredentials([
        [$class: 'AmazonWebServicesCredentialsBinding',
         credentialsId: 'aws-creds',
         accessKeyVariable: 'AWS_ACCESS_KEY_ID',
         secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']
      ]) {
        sh "terraform -chdir=${tfDir} apply -auto-approve tfplan"
      }
    }
  }
}
