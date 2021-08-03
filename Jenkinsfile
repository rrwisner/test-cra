pipeline {
    environment {
        registry = "codehutlabs/cra-runtime-environment-variables"
        registryCredential = 'dockerhub_id'
        dockerImage = ''
        CI = 'true'
    }
    agent any
    stages {
        stage('Build ...') {
            agent {
                docker {
                    image 'node:alpine'
                    args '-p 3000:3000 -v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker'
                }
            }
            steps {
                echo 'Building ...'
                sh 'yarn'
            }
        }
        stage('Test') {
            agent {
                docker {
                    image 'node:alpine'
                    args '-p 3000:3000 -v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker'
                }
            }
            steps {
                echo 'Testing ...'
                sh 'yarn test'
            }
        }
        stage('Build image') {
            steps {
                echo 'Building image ...'
                script {
                    dockerImage = docker.build registry
                }
            }
        }
        stage('Upload image') {
            steps {
                echo 'Uploading image ...'
                script {
                    docker.withRegistry('', registryCredential) {
                        dockerImage.push()
                    }
                }
            }
        }
        stage('Deploy to EKS') {
            steps {
                echo 'Deploying to EKS ...'
                sh 'helm install --generate-name ./charts/cra'
            }
        }
    }
}
