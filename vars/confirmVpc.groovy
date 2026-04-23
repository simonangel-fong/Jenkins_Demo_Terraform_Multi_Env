def call(String env, String awsRegion) {
  stage("${env}: Confirm VPC") {
    container('terraform') {
      withCredentials([
        [$class: 'AmazonWebServicesCredentialsBinding',
         credentialsId: 'aws-creds',
         accessKeyVariable: 'AWS_ACCESS_KEY_ID',
         secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']
      ]) {
        def vpcId = sh(
          script: """
            aws ec2 describe-vpcs \
              --region ${awsRegion} \
              --filters \
                "Name=tag:Project,Values=jenkins-terraform" \
                "Name=tag:Environment,Values=${env}" \
                "Name=tag:ManagedBy,Values=terraform" \
              --query "Vpcs[0].VpcId" \
              --output text
          """,
          returnStdout: true
        ).trim()

        if (!vpcId || vpcId == 'None') {
          error("VPC not found for environment '${env}' (Project=jenkins-terraform, Environment=${env}, ManagedBy=terraform)")
        }

        echo "VPC confirmed for environment '${env}': ${vpcId}"
      }
    }
  }
}
