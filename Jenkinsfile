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
      name: 'nodejs',
      image:'node:alpine',
      ttyEnabled: true,
      alwaysPullImage: false
    ),
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

    stage('Vet and Test') {
      container('nodejs') {
        def scmVars = checkout scm
        env.CI = true
        sh "yarn"

        parallel (
          'Vet': {
            try {
              sh "yarn lint"
            } catch (e) {
              echo('detected failure: Vet stage')
              throw(e)
            }
          },

          'Test': {
            try {
              sh "yarn test"
            } catch (e) {
              echo('detected failure: Test stage')
              throw(e)
            }
          }
        )
      }
    }

    stage('Setup') {
      container('main') {
        def scmVars = checkout scm
        env.GIT_COMMIT = scmVars.GIT_COMMIT
        env.GIT_BRANCH = scmVars.GIT_BRANCH
        env.IMAGE = "$DOCKER_REPOSITORY:branch-$GIT_BRANCH"

        sh "echo ${env.GIT_BRANCH};"

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

    stage('Publish') {
      container('main') {

        try {
          // ship assets to specified destination
          sh """
            docker run \
              --network=host \
              -e AWS_ACCESS_KEY_ID=\$AWS_ACCESS_KEY_ID \
              -e AWS_SECRET_ACCESS_KEY=\$AWS_SECRET_ACCESS_KEY \
              -e AWS_BUCKET_NAME=joor-react-testing \
              -e REF=$REF \
              -e VERSION_ID=$GIT_COMMIT \
              -e GIT_BRANCH=$GIT_BRANCH \
              -e MAINLINE_BRANCH=$MAINLINE_BRANCH \
              -e COMMIT=$GIT_COMMIT \
              -e SENTRY_TOKEN=\$SENTRY_AUTH_TOKEN \
              --entrypoint=bash \
              $IMAGE \
              publish.sh
          """

          // push stable reference for mainline branch
          if (env.GIT_BRANCH == "$MAINLINE_BRANCH") {
            env.COMMIT_TAG = "$DOCKER_REPOSITORY:$GIT_COMMIT"

            // push an image to ECR for use in local dev
            sh """
              aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $DOCKER_REPOSITORY_BASE
            """

            // ensure the image is tagged with both commit SHA and branch
            // sh """
            //   docker push $IMAGE
            //   docker tag $IMAGE $COMMIT_TAG
            //   docker push $COMMIT_TAG
            // """
          }
        } catch (e) {
          echo('detected failure: Publish stage')
          throw(e)
        }
      }
    }
  }
}
