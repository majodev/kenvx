### -----------------------
# --- Variables
### -----------------------

KUBECTL_DEFAULT_VERSION := 1.32
JQ_DEFAULT_VERSION := 1.7.1

KUBECTL_VERSIONS := 1.28 1.29 1.30 1.31 1.32
JQ_VERSIONS := 1.6 1.7.1

### -----------------------
# --- Building & Testing
### -----------------------

.PHONY: all
all:
	$(MAKE) build
	$(MAKE) test

.PHONY: build
build: format lint

.PHONY: info
info:
	@shellcheck --version
	@shellharden --version

.PHONY: format
format:
	@shellharden --replace kenvx
	@shellharden --replace test/*.bats

.PHONY: lint
lint:
	@shellcheck -x kenvx
	@shellcheck -x test/*.bats
	@shellharden --check kenvx
	@shellharden --check test/*.bats

.PHONY: test
test:
	@bash test/kind_init.sh
	$(MAKE) test-version KUBECTL_VERSION=$(KUBECTL_DEFAULT_VERSION) JQ_VERSION=$(JQ_DEFAULT_VERSION)

# e.g. make test-version KUBECTL_VERSION=1.32 JQ_VERSION=1.7.1
.PHONY: test-version
test-version:
	@if [ -z "$(KUBECTL_VERSION)" ]; then echo "KUBECTL_VERSION is required"; exit 1; fi
	@if [ -z "$(JQ_VERSION)" ]; then echo "JQ_VERSION is required"; exit 1; fi
	@echo "=== Testing with kubectl v$(KUBECTL_VERSION) and jq v$(JQ_VERSION) ==="
	@( \
		temp_dir=$$(mktemp -d); \
		trap 'rm -rf "$$temp_dir"' EXIT; \
		ln -s "/opt/jq/bin/jq-$(JQ_VERSION)" "$$temp_dir/jq"; \
		ln -s "/opt/kubectl/bin/kubectl-$(KUBECTL_VERSION)" "$$temp_dir/kubectl"; \
		PATH="$$temp_dir:$$PATH" \
		bash -c 'kubectl version --client && jq --version && bats test' \
	)

.PHONY: test-matrix
test-matrix:
	@bash test/kind_init.sh
	@for k in $(KUBECTL_VERSIONS); do \
		for j in $(JQ_VERSIONS); do \
			$(MAKE) test-version KUBECTL_VERSION=$$k JQ_VERSION=$$j || exit 1; \
		done; \
	done

### -----------------------
# --- Kind
### -----------------------

# kind, these steps are meant to run locally on your machine directly!
# https://johnharris.io/2019/04/kubernetes-in-docker-kind-of-a-big-deal/

.PHONY: kind-cluster-clean
kind-cluster-clean:
	kind delete cluster --name kenvx
	rm -rf .kube/**

# https://hub.docker.com/r/kindest/node/tags
.PHONY: kind-cluster-init
kind-cluster-init:
	kind create cluster --name kenvx --config=test/kind.yaml --kubeconfig .kube/config --image "kindest/node:v1.31.4"
	$(MAKE) kind-fix-kubeconfig
	sleep 1
	$(MAKE) kind-cluster-init-script

.PHONY: kind-fix-kubeconfig
kind-fix-kubeconfig:
	sed -i.bak -e 's/127.0.0.1/host.docker.internal/' .kube/config

.PHONY: kind-cluster-init-script
kind-cluster-init-script:
	docker-compose up --no-start
	docker-compose start
	docker-compose exec service bash test/kind_init.sh

.PHONY: kind-cluster-reset
kind-cluster-reset:
	$(MAKE) kind-cluster-clean
	$(MAKE) kind-cluster-init

### -----------------------
# --- Special targets
### -----------------------

# https://unix.stackexchange.com/questions/153763/dont-stop-makeing-if-a-command-fails-but-check-exit-status
# https://www.gnu.org/software/make/manual/html_node/One-Shell.html
# required to ensure make fails if one recipe fails (even on parallel jobs) and on pipefails
.ONESHELL:

# normal POSIX bash shell mode
SHELL = /bin/bash
.SHELLFLAGS = -cEeuo pipefail