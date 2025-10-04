pipeline {
  agent { label 'Jenkins-Agent' }
  tools {
    jdk 'Java17'
    maven 'Maven3'
  }
  stages {
    stage ("Cleanup Workspace"){
            steps {
              cleanWs()
            }
    }

    stage("Checkout from SCM"){
            steps {
            git branch: 'main', credentialsID: 'github', url: 'https://github.com/Phoenix-ctrl-cpu/Prayag-new1'
            }
    }

    stage("Build Application"){
            steps {
            sh "mvn clean package'
            }
    }

    stage("Test Application"){
            steps {
            sh "mvn test
            }
    }
  }
}
