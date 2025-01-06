#!/bin/bash
set -Eeo pipefail

# Exit immediately if the current kubectl context is not kind-kubectl-envx
if [[ $(kubectl config current-context) != "kind-kubectl-envx" ]]; then
  echo "Current kubectl context is not kind-kubectl-envx"
  exit 1
fi

kubectl config set-context --current --namespace default
kubectl delete job/sample || true
kubectl apply -f ./test/manifests/

kubectl rollout status deployment sample
echo