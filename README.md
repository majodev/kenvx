# kenvx

### Development Setup

```bash
 Ensure you have docker (for mac) and kind installed on your **local** host.
# This project requires kind (Kubernetes in Docker) to do the testing.

# Launch a new kind cluster on your *LOCAL* host:
brew install kind
make kind-cluster-init

# the dev container is autoconfigured to use the above kind cluster
./docker-helper --up

development@da38d91ede55:/app$ k get nodes
# NAME                  STATUS   ROLES           AGE   VERSION
# kenvx-control-plane   Ready    control-plane   25m   v1.31.4

development@da38d91ede55:/app$ make
```