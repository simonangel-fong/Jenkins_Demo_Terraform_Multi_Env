@Library('my-shared-library') _

@Library('jenkins-terraform-shared-lib') _

pipeline {
    agent any

    stages {
        stage('Greeting') {
            steps {
                // This calls the code in vars/sayHi.groovy
                sayHi()
            }
        }
    }
}