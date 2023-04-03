#!/usr/bin/env bash
set -o errexit -o errtrace -o nounset -o pipefail

# shellcheck source=build.sh
source ./bin/build.sh

INSTALL_DIR="/usr/local/bin"

# Ensure install dir
if [[ ! -d "${INSTALL_DIR}" ]]; then
    sudo mkdir -p "${INSTALL_DIR}"
fi

# Don't interrupt the user w/ sudo prompts unless actually needed.
prefix=""
if [[ ! -w "${INSTALL_DIR}" ]]; then
    prefix="sudo"
fi

$prefix install -m755 "${BUILD_PATH}" "${INSTALL_DIR}/"
