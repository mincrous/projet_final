pipeline {
    agent any

    options {
        skipDefaultCheckout(true)
    }

    environment {
        IMAGE = 'mangmichellem/ic-webapp'
    }

    stages {
        stage('Récupérer le code') {
            steps {
                checkout scm
            }
        }

        stage('Lire la version') {
            steps {
                script {
                    env.APP_VERSION = sh(
                        script: '''awk -F': ' '$1 == "version" { print $2 }' releases.txt''',
                        returnStdout: true
                    ).trim()

                    if (!env.APP_VERSION) {
                        error('La version est absente de releases.txt')
                    }

                    echo "Version à construire : ${env.APP_VERSION}"
                }
            }
        }

        stage('Construire l’image Docker') {
            steps {
                sh 'docker build -t "$IMAGE:$APP_VERSION" .'
            }
        }

        stage('Publier sur Docker Hub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-account',
                    usernameVariable: 'DOCKERHUB_USER',
                    passwordVariable: 'DOCKERHUB_TOKEN'
                )]) {
                    sh '''
                        set +x
                        printf '%s' "$DOCKERHUB_TOKEN" |
                            docker login --username "$DOCKERHUB_USER" --password-stdin
                        docker push "$IMAGE:$APP_VERSION"
                    '''
                }
            }
        }

        stage('Déployer avec Ansible') {
            steps {
                withCredentials([
                    string(credentialsId: 'odoo-db-password', variable: 'ODOO_DB_PASSWORD'),
                    string(credentialsId: 'pgadmin-default-password', variable: 'PGADMIN_DEFAULT_PASSWORD')
                ]) {
                    sh '''
                        set +x
                        cd ansible
                        ansible-playbook -i localhost, playbooks/site.yml
                    '''
                }
            }
        }

        stage('Déployer IC WebApp') {
            steps {
                sh '''
                    docker rm -f ic-webapp 2>/dev/null || true
                    docker run -d --name ic-webapp --restart unless-stopped \
                        -p 8085:8080 \
                        -e ODOO_URL=http://localhost:8069 \
                        -e PGADMIN_URL=http://localhost:8084 \
                        "$IMAGE:$APP_VERSION"
                '''
            }
        }
    }

    post {
        always {
            sh 'docker logout || true'
        }
    }
}