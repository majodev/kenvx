# kenvx

### Development setup

```bash
# Ensure you have docker and kind installed on your **local** host.
# This project requires kind (Kubernetes in Docker) to do the testing.

# Launch a new kind cluster on your *LOCAL* host:
brew install kind
make kind-cluster-init

# the dev container is autoconfigured to use the above kind cluster
./docker-helper --up

development@da38d91ede55:/app$ k get nodes
# NAME                  STATUS   ROLES           AGE   VERSION
# kenvx-control-plane   Ready    control-plane   25m   v1.31.4

# Runs lint and tests
development@20c533ecf4c7:/app$ make
# make build
# make test
# kenvx.bats
#  ✓ fails on missing arguments
#  ✓ fails on invalid resource kind
#  ✓ fails on invalid resource name
#  ✓ deployment/noenv: prints ENV (nothing)
#  ✓ deployment/noenv: exec with ENV
#  ✓ deployment/emptyenv: prints ENV (nothing)
#  ✓ deployment/emptyenv: exec with ENV
#  ✓ deployment/sample: prints ENV
#  ✓ deployment/sample: exec with ENV
#  [...]
```