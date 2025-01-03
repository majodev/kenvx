#!/bin/bash
set -Eeox pipefail

kubectl version
kubectl get nodes
kubectl config current-context

# Exit immediately if the current kubectl context is not kind-kenvx
if [[ $(kubectl config current-context) != "kind-kenvx" ]]; then
  echo "Current kubectl context is not kind-kenvx"
  exit 1
fi

kubectl apply -f ./test/manifests/