# https://hub.docker.com/r/bitnami/kubectl/tags
FROM bitnami/kubectl:1.32 as kubectl-1.32
FROM bitnami/kubectl:1.31 as kubectl-1.31
FROM bitnami/kubectl:1.30 as kubectl-1.30
FROM bitnami/kubectl:1.29 as kubectl-1.29
FROM bitnami/kubectl:1.28 as kubectl-1.28

### -----------------------
# --- Stage: development
# --- Purpose: Local development environment
### -----------------------
FROM debian:bookworm AS development

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Our Makefile / env fully supports parallel job execution
ENV MAKEFLAGS "-j 8 --no-print-directory"

# Install required system dependencies
RUN apt-get update \
    && apt-get install -y \
    #
    # Mandadory minimal linux packages
    # Installed at development stage and app stage
    # Do not forget to add mandadory linux packages to the final app Dockerfile stage below!
    # 
    # -- START MANDADORY --
    ca-certificates \
    # --- END MANDADORY ---
    # 
    # Development specific packages
    # Only installed at development stage and NOT available in the final Docker stage
    # based upon
    # https://github.com/microsoft/vscode-remote-try-go/blob/master/.devcontainer/Dockerfile
    # https://raw.githubusercontent.com/microsoft/vscode-dev-containers/master/script-library/common-debian.sh
    #
    # icu-devtools: https://stackoverflow.com/questions/58736399/how-to-get-vscode-liveshare-extension-working-when-running-inside-vscode-remote
    # graphviz: https://github.com/google/pprof#building-pprof
    # -- START DEVELOPMENT --
    apt-utils \
    bats \
    bats-assert \
    bats-support \
    bash-completion \
    bsdmainutils \
    curl \
    dialog \
    gdb \
    git \
    graphviz \
    icu-devtools \
    iproute2 \
    jq \
    less \
    locales \
    lsb-release \
    make \
    openssh-client \
    procps \
    rsync \
    shellcheck \
    sudo \
    tmux \
    wget \
    xz-utils \
    # --- END DEVELOPMENT ---
    # 
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# shellharden bash script hardening
RUN set -x; ARCH="$(uname -m)" \
    && SHELLHARDEN_TMP="$(mktemp -d)" \
    && SHELLHARDEN_VERSION="4.3.1" \
    && cd "${SHELLHARDEN_TMP}" \
    && curl -fsSLO "https://github.com/anordal/shellharden/releases/download/v${SHELLHARDEN_VERSION}/shellharden-${ARCH}-unknown-linux-gnu.tar.gz" \
    && tar zxvf "shellharden-${ARCH}-unknown-linux-gnu.tar.gz" \
    && chmod +x shellharden \
    && cp shellharden /usr/local/bin/shellharden \
    && rm -rf "${SHELLHARDEN_TMP}"

# env/vscode support: LANG must be supported, requires installing the locale package first
# https://github.com/Microsoft/vscode/issues/58015
# https://stackoverflow.com/questions/28405902/how-to-set-the-locale-inside-a-debian-ubuntu-docker-container
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8

ENV LANG en_US.UTF-8

# watchexec
# https://github.com/watchexec/watchexec/releases
RUN mkdir -p /tmp/watchexec \
    && cd /tmp/watchexec \
    && wget https://github.com/watchexec/watchexec/releases/download/v1.25.1/watchexec-1.25.1-$(arch)-unknown-linux-musl.tar.xz \
    && tar xf watchexec-1.25.1-$(arch)-unknown-linux-musl.tar.xz \
    && cp watchexec-1.25.1-$(arch)-unknown-linux-musl/watchexec /usr/local/bin/watchexec \
    && rm -rf /tmp/watchexec

# https://helm.sh/docs/intro/install/
RUN set -x; HELM_TMP="$(mktemp -d)" \
    && HELM_VERSION="3.16.0" \
    && cd "${HELM_TMP}" \
    && ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" \
    && HELM="helm-v${HELM_VERSION}-linux-${ARCH}" \
    && curl -fsSLO "https://get.helm.sh/${HELM}.tar.gz" \
    && tar zxvf "${HELM}.tar.gz" \
    && chmod +x linux-${ARCH}/helm \
    && cp linux-${ARCH}/helm /usr/local/bin/helm \
    && chown $USERNAME:$USERNAME /usr/local/bin/helm \
    && rm -rf "${HELM_TMP}" \
    # kex
    # https://github.com/farmotive/kex
    && KEX_TMP="$(mktemp -d)" \
    && KEX_VERSION="1.2.2" \
    && cd "${KEX_TMP}" \
    && curl -fsSLO "https://github.com/farmotive/kex/archive/refs/tags/v${KEX_VERSION}.tar.gz" \
    && tar zxvf "v${KEX_VERSION}.tar.gz" \
    && chmod +x kex-${KEX_VERSION}/kex \
    && cp kex-${KEX_VERSION}/kex /usr/local/bin/kex \
    && chown $USERNAME:$USERNAME /usr/local/bin/kex \
    && rm -rf "${KEX_TMP}" \
    # k9s
    # https://github.com/derailed/k9s/releases
    && K9S_TMP="$(mktemp -d)" \
    && K9S_VERSION="0.32.5" \
    && cd "${K9S_TMP}" \
    && ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" \
    && curl -fsSLO "https://github.com/derailed/k9s/releases/download/v${K9S_VERSION}/k9s_Linux_${ARCH}.tar.gz" \
    && tar zxvf "k9s_Linux_${ARCH}.tar.gz" \
    && chmod +x k9s \
    && cp k9s /usr/local/bin/k9s \
    && chown $USERNAME:$USERNAME /usr/local/bin/k9s \
    && rm -rf "${K9S_TMP}" \
    # yq
    # https://github.com/mikefarah/yq/releases
    && YQ_TMP="$(mktemp -d)" \
    && YQ_VERSION="4.44.3" \
    && cd "${YQ_TMP}" \
    && ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" \
    && curl -fsSLO "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${ARCH}.tar.gz" \
    && tar zxvf "yq_linux_${ARCH}.tar.gz" \
    && chmod +x "yq_linux_${ARCH}" \
    && cp "yq_linux_${ARCH}" /usr/local/bin/yq \
    && chown $USERNAME:$USERNAME /usr/local/bin/yq \
    && rm -rf "${YQ_TMP}"


# linux permissions / vscode support: Add user to avoid linux file permission issues
# Detail: Inside the container, any mounted files/folders will have the exact same permissions
# as outside the container - including the owner user ID (UID) and group ID (GID). 
# Because of this, your container user will either need to have the same UID or be in a group with the same GID.
# The actual name of the user / group does not matter. The first user on a machine typically gets a UID of 1000,
# so most containers use this as the ID of the user to try to avoid this problem.
# 2020-04: docker-compose does not support passing id -u / id -g as part of its config, therefore we assume uid 1000
# https://code.visualstudio.com/docs/remote/containers-advanced#_adding-a-nonroot-user-to-your-dev-container
# https://code.visualstudio.com/docs/remote/containers-advanced#_creating-a-nonroot-user
ARG USERNAME=development
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# vscode support: cached extensions install directory
# https://code.visualstudio.com/docs/remote/containers-advanced#_avoiding-extension-reinstalls-on-container-rebuild
RUN mkdir -p /home/$USERNAME/.vscode-server/extensions \
    /home/$USERNAME/.vscode-server-insiders/extensions \
    && chown -R $USERNAME \
    /home/$USERNAME/.vscode-server \
    /home/$USERNAME/.vscode-server-insiders

# https://code.visualstudio.com/remote/advancedcontainers/persist-bash-history
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/home/$USERNAME/commandhistory/.bash_history" \
    && mkdir /home/$USERNAME/commandhistory \
    && touch /home/$USERNAME/commandhistory/.bash_history \
    && chown -R $USERNAME /home/$USERNAME/commandhistory \
    && echo "$SNIPPET" >> "/home/$USERNAME/.bashrc"

WORKDIR /app

# krew
# https://github.com/kubernetes-sigs/krew/releases
ENV KREW_ROOT /opt/krew
RUN set -x; KREW_TMP="$(mktemp -d)" \
    && cd "${KREW_TMP}" \
    && KREW_VERSION="0.4.4" \
    && ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" \
    && KREW="krew-linux_${ARCH}" \
    && curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/download/v${KREW_VERSION}/${KREW}.tar.gz" \
    && tar zxvf "${KREW}.tar.gz" \
    && ./"${KREW}" install krew \
    && rm -rf "${KREW_TMP}"
ENV PATH $PATH:$KREW_ROOT/bin

# add all currently supported kubectl versions by kenvx
# https://hub.docker.com/r/bitnami/kubectl/tags
COPY --from=kubectl-1.32 /opt/bitnami/kubectl/bin/kubectl /opt/kubectl/bin/kubectl-1.32
COPY --from=kubectl-1.31 /opt/bitnami/kubectl/bin/kubectl /opt/kubectl/bin/kubectl-1.31
COPY --from=kubectl-1.30 /opt/bitnami/kubectl/bin/kubectl /opt/kubectl/bin/kubectl-1.30
COPY --from=kubectl-1.29 /opt/bitnami/kubectl/bin/kubectl /opt/kubectl/bin/kubectl-1.29
COPY --from=kubectl-1.28 /opt/bitnami/kubectl/bin/kubectl /opt/kubectl/bin/kubectl-1.28
RUN ln -s /opt/kubectl/bin/kubectl-1.32 /opt/kubectl/bin/kubectl \
    && chown -R $USERNAME:$USERNAME /opt/kubectl/bin
ENV PATH $PATH:/opt/kubectl/bin

# add all currently supported jq versions by kenvx
# version 1.6 comes via the package manager.
# https://github.com/jqlang/jq/releases
RUN mkdir -p /opt/jq/bin \
    && ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" \
    && VERSION="1.7.1" && curl -fsSL "https://github.com/jqlang/jq/releases/download/jq-${VERSION}/jq-linux-${ARCH}" -o "/opt/jq/bin/jq-${VERSION}" && chmod +x "/opt/jq/bin/jq-${VERSION}" \
    && ln -s /usr/bin/jq /opt/jq/bin/jq-1.6 \
    && ln -s /opt/jq/bin/jq-1.7.1 /opt/jq/bin/jq \
    && chown -R $USERNAME:$USERNAME /opt/jq/bin
ENV PATH /opt/jq/bin:$PATH

# install kubectl plugins via krew
# https://krew.sigs.k8s.io/plugins/
# -> https://github.com/stern/stern
# -> https://github.com/ahmetb/kubectx
# -> https://github.com/patrickdappollonio/kubectl-slice
# hack: we chown to $USERNAME to avoid permission issues when running the container
RUN kubectl krew install stern ctx ns slice \
    && chown -R $USERNAME $KREW_ROOT

# typical k8s aliases/completions and other .bashrc modifications
RUN echo 'source <(kubectl completion bash)' >>/home/$USERNAME/.bashrc \
    && echo 'alias k=kubectl' >>/home/$USERNAME/.bashrc \
    && echo 'complete -o default -F __start_kubectl k' >>/home/$USERNAME/.bashrc \
    # https://github.com/ahmetb/kubectx
    && echo 'alias ks="kubectl ns \$(basename \$(pwd))"' >>/home/$USERNAME/.bashrc \
    && echo 'alias kubens="kubectl ns"' >>/home/$USERNAME/.bashrc \
    && echo 'alias kc="kubectl ctx \$(basename \$(pwd))"' >>/home/$USERNAME/.bashrc \
    && echo 'alias kubectx="kubectl ctx"' >>/home/$USERNAME/.bashrc \
    # https://github.com/stern/stern
    && echo 'source <(kubectl stern --completion bash)' >>/home/$USERNAME/.bashrc \
    && echo 'alias stern="kubectl stern"' >>/home/$USERNAME/.bashrc \
    # https://kubernetes.io/docs/reference/kubectl/cheatsheet/ + https://faun.pub/be-fast-with-kubectl-1-18-ckad-cka-31be00acc443
    && echo "alias kx='f() { [ "\$1" ] && kubectl config use-context \$1 || kubectl config current-context ; } ; f'" >>/home/$USERNAME/.bashrc \
    && echo "alias kn='f() { [ "\$1" ] && kubectl config set-context --current --namespace \$1 || kubectl config view --minify | grep namespace | cut -d" " -f6 ; } ; f'" >>/home/$USERNAME/.bashrc \
    && echo 'export do="--dry-run=client -o yaml"' >>/home/$USERNAME/.bashrc \
    && echo 'syntax on' >>/home/$USERNAME/.vimrc \
    && echo 'set ts=2 sw=2 et' >>/home/$USERNAME/.vimrc

### -----------------------
# --- Stage: builder
# --- Purpose: Statically built binaries and CI environment
### -----------------------

FROM development as builder
WORKDIR /app
COPY . /app/
RUN make info && make lint
