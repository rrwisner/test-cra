#!/usr/bin/env groovy

env.DOCKER_PROJECT="test-cra"
env.DOCKER_REPOSITORY_BASE = '714845803326.dkr.ecr.us-east-1.amazonaws.com'
env.DOCKER_REPOSITORY="$DOCKER_REPOSITORY_BASE/$DOCKER_PROJECT"
env.MAINLINE_BRANCH="main"
env.SLACK_CHANNEL="#pod-icarus"

// guarantee this podtemplate is always unique to avoid a bug where executors
// with matching names collide with eachother and prevent scheduling
def label = "test-cra-${UUID.randomUUID().toString()}"

podTemplate(
    label: label,
    slaveConnectTimeout: 720,
    containers: [
        containerTemplate(
            name: 'main',
            // the dockerfile for this is in joor-devenv/apps/builder
            image: '714845803326.dkr.ecr.us-east-1.amazonaws.com/joor-builder',
            ttyEnabled: true,
            // override default command to something long running so the jenkins slave
            // has a chance to connect. As per jenkins-pipeline docs.
            command: 'cat',
            envVars: [
                secretEnvVar(
                    key: 'AWS_ACCESS_KEY_ID',
                    secretName: 'cicd-jenkins-generic',
                    secretKey: 'aws_access_key_id.value'
                ),
                secretEnvVar(
                    key: 'AWS_SECRET_ACCESS_KEY',
                    secretName: 'cicd-jenkins-generic',
                    secretKey: 'aws_secret_access_key.value'
                ),
                secretEnvVar(
                    key: 'SENTRY_AUTH_TOKEN',
                    secretName: 'cicd-sentry',
                    secretKey: 'token.value'
                ),
                secretEnvVar(
                    key: 'NPM_TOKEN',
                    secretName: 'cicd-joorbot',
                    secretKey: 'joorbot-designsystem-token'
                )
            ],
            resourceRequestCpu: '700m',
            resourceRequestMemory: '2Gi',
        )
    ]
)
{
    node(label) {
        stage('Setup') {
            container('main') {
                def scmVars = checkout scm
                sh 'echo hello world'
                sh 'yarn'
            }
        }
    }
}
