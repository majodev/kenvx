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
	@bats test

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