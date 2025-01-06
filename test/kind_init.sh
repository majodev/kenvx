#!/bin/bash
set -Eeo pipefail

# Exit immediately if the current kubectl context is not kind-kenvx
if [[ $(kubectl config current-context) != "kind-kenvx" ]]; then
  echo "Current kubectl context is not kind-kenvx"
  exit 1
fi

kubectl config set-context --current --namespace default
kubectl delete job/sample || true
kubectl apply -f ./test/manifests/

kubectl rollout status deployment sample