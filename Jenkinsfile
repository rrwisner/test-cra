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
  ],
  volumes: [
    // mount the host's docker socket so we can build docker images
    // and reuse cache across builds on the same node
    hostPathVolume(
      mountPath: '/var/run/docker.sock',
      hostPath:  '/var/run/docker.sock'
    ),
  ]
)
{
  node(label) {

    stage('Setup') {
      container('main') {
        def scmVars = checkout scm
        env.GIT_COMMIT = scmVars.GIT_COMMIT
        env.GIT_BRANCH = scmVars.GIT_BRANCH
        env.IMAGE = "$DOCKER_REPOSITORY:branch-$GIT_BRANCH"

        if (!env.GIT_BRANCH.matches("[a-zA-Z0-9\\._-]+")) {
          error "A feature branch namespace may only contain the following characters a-z, A-Z, 0-9, -, _, ~."
        }

        if (env.ref) {
          env.REF = env.ref
        } else {
          env.REF = "branch-$GIT_BRANCH"
        }

        sh "docker build --build-arg NPM_TOKEN_ARG=\$NPM_TOKEN --network=host -t $IMAGE ."
      }
    }

    stage('Vet and Test') {
      container('main') {
        parallel (
          'Vet': {
            try {
              sh "docker run $IMAGE npm run lint -- --quiet"
            } catch (e) {
              echo('detected failure: Vet stage')
              throw(e)
            }
          },

          'Test': {
            try {
              sh "docker run -e CI=true $IMAGE npm run test -- --maxWorkers=3"
            } catch (e) {
              echo('detected failure: Test stage')
              throw(e)
            }
          }
        )
      }
    }

  }
}
