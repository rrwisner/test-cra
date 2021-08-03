podTemplate(
    containers: [
        containerTemplate(
            name: 'nodejs',
            image:'node:alpine',
            ttyEnabled: true,
            alwaysPullImage: false
        ),
    ]
)
{
    node(POD_LABEL) {
        stage('Build') {
            def scmVars = checkout scm
            container('nodejs') {
                sh 'echo hello world'
                sh 'yarn'
            }
        }
    }
}
