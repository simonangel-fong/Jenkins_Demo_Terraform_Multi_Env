@Library('my-shared-library') _

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