# syntax=docker/dockerfile:1.4
#######################################################
# APP_TARGET: full
#
# All of the dev/test/build tools
#######################################################
FROM ghcr.io/gostamp/ubuntu-full:0.5.0 AS full

SHELL ["/bin/bash", "-o", "pipefail", "-o", "errexit", "-c"]

USER root
ARG TARGETARCH

RUN <<EOF
    # Install Go
    VERSION="1.20.3"
    if [[ "${TARGETARCH}" == "amd64" ]]; then
        CHECKSUM="979694c2c25c735755bf26f4f45e19e64e4811d661dd07b8c010f7a8e18adfca"
    elif [[ "${TARGETARCH}" == "arm64" ]]; then
        CHECKSUM="eb186529f13f901e7a2c4438a05c2cd90d74706aaa0a888469b2a4a617b6ee54"
    else
        echo "Unknown arch: '${TARGETARCH}'!" && exit 1
    fi
    TARFILE="go${VERSION}.linux-${TARGETARCH}.tar.gz"

    curl -fsSL "https://go.dev/dl/${TARFILE}" > "${TARFILE}"
    echo "${CHECKSUM}  ${TARFILE}" | sha256sum --check --quiet -
    rm -rf /usr/local/go
    tar -C /usr/local -xvf "${TARFILE}"
    rm -f "${TARFILE}"
EOF

RUN <<EOF
    # Install Go dev tools

    # Switch Go paths so we don't bloat the image w/ pkg and cache files.
    mkdir -p /tmp/gotools
    pushd /tmp/gotools || exit
    export GOPATH=/tmp/gotools
    export GOCACHE=/tmp/gotools/cache

    GO_TOOLS="\
        golang.org/x/tools/gopls@latest \
        honnef.co/go/tools/cmd/staticcheck@latest \
        github.com/uudashr/gopkgs/v2/cmd/gopkgs@latest \
        github.com/ramya-rao-a/go-outline@latest \
        github.com/go-delve/delve/cmd/dlv@latest \
        github.com/haya14busa/goplay/cmd/goplay@latest \
        github.com/fatih/gomodifytags@latest \
        github.com/josharian/impl@latest \
        github.com/cweill/gotests/gotests@latest \
        github.com/goreleaser/goreleaser@latest \
        github.com/orlangure/gocovsh@latest \
        github.com/matryer/moq@latest"
    echo "${GO_TOOLS}" | xargs -n1 /usr/local/go/bin/go install -v

    # Move Go tools to GOPATH and clean up
    if [ -d /tmp/gotools/bin ]; then
        mv /tmp/gotools/bin/* /usr/local/bin/
    fi
    popd || exit
    rm -rf /tmp/gotools
    unset GOPATH
    unset GOCACHE

    # Install golangci-lint
    curl -fsSL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | \
        sh -s -- -b /usr/local/bin
EOF

# Drop down to the app user
USER app

ENV PATH="${PATH}:/usr/local/go/bin:/home/app/go/bin"

#######################################################
# APP_TARGET: slim
#
# A minimal image w/ just the app
#######################################################
FROM ghcr.io/gostamp/ubuntu-slim:0.5.0 AS slim
