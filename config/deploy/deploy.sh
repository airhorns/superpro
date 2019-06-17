#!/usr/bin/env bash
# This script is run by the CD platform to deploy the app.
set -ex
export KUBECONFIG=${HOME}/.kube/config
export ENVIRONMENT=production
export CLUSTER="gke_omp-core_us-central1-a_beta"

GIT_SHA=$(git rev-parse HEAD)
export REVISION=${REVISION:-$GIT_SHA}
DEPLOY_COMMAND="bundle exec kubernetes-deploy"

# deploy application to it's namespace
bundle exec kubernetes-deploy --template-dir=config/deploy/$ENVIRONMENT core-production $CLUSTER
