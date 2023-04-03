#!/usr/bin/env bash
set -o errexit -o errtrace -o nounset -o pipefail

# cspell: words Iseconds trimpath ldflags

os=$(uname -s | tr '[:upper:]' '[:lower:]')
arch=$(uname -m)

APP_NAME="${APP_NAME?}"
BUILD_DIR="./dist/${os}-${arch}"
BUILD_PATH="${BUILD_DIR}/${APP_NAME}"
CURRENT_SHA=$(git rev-parse --short HEAD)
CURRENT_TS=$(date -Iseconds)

mkdir -p "${BUILD_DIR}"

# Build
go mod tidy
go build \
    -trimpath \
    -ldflags="-X main.version=dev -X main.commit=${CURRENT_SHA} -X main.date=${CURRENT_TS}" \
    -o "${BUILD_PATH}" \
    .

# Show the size of the built executable.
du -h "${BUILD_PATH}"
