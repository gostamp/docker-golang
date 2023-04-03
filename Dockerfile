# syntax=docker/dockerfile:1.4
#######################################################
# APP_TARGET: full
#
# All of the dev/test/build tools
#######################################################
FROM ghcr.io/gostamp/ubuntu-full:0.4.0 AS full

SHELL ["/bin/bash", "-o", "pipefail", "-o", "errexit", "-c"]

USER root
ARG TARGETARCH

RUN <<EOF
    # Install Go
    VERSION="1.20.2"
    if [[ "${TARGETARCH}" == "amd64" ]]; then
        CHECKSUM="4eaea32f59cde4dc635fbc42161031d13e1c780b87097f4b4234cfce671f1768"
    elif [[ "${TARGETARCH}" == "arm64" ]]; then
        CHECKSUM="78d632915bb75e9a6356a47a42625fd1a785c83a64a643fedd8f61e31b1b3bef"
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
        mkdir -p /home/app/go/bin
        mv /tmp/gotools/bin/* /home/app/go/bin/
    fi
    popd || exit
    rm -rf /tmp/gotools
    unset GOPATH
    unset GOCACHE

    # Install golangci-lint
    curl -fsSL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | \
        sh -s -- -b /home/app/go/bin

    chown -R app:app /home/app/go/bin
EOF

# Drop down to the app user
USER app

ENV PATH="${PATH}:/usr/local/go/bin:/home/app/go/bin"

# Copy app source
COPY . ${APP_DIR}

ENTRYPOINT ["/app/bin/entrypoint.sh"]
CMD ["/app/bin/run.sh"]
