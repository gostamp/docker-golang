#!/usr/bin/env bash
set -o errexit -o errtrace -o nounset -o pipefail

# If SOPS config exists and is non-empty...
if [[ -s .sops.yaml ]]; then
    # Create secrets files if needed.
    if [[ ! -f etc/local/secrets.yml ]]; then
        echo "---" >etc/local/secrets.yml
        sops -e -i etc/local/secrets.yml 2>/dev/null
    fi
    if [[ ! -f etc/test/secrets.yml ]]; then
        echo "---" >etc/test/secrets.yml
        sops -e -i etc/test/secrets.yml 2>/dev/null
    fi
fi
