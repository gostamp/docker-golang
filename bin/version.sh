#!/usr/bin/env bash
set -o errexit -o errtrace -o nounset -o pipefail

# We need a token for `gh`.
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
if [[ "${GITHUB_TOKEN}" == "" ]]; then
    echo "🔴 The GITHUB_TOKEN environment variable must be set."
    echo "   If running locally, uncomment that line in the Makefile."
    exit 1
fi

# cspell: words koozz
if ! gh extension list | grep -q "koozz/gh-semver"; then
    gh extension install koozz/gh-semver &>/dev/null
fi
git fetch --all --tags 1>&2

CURRENT_BRANCH=$(git symbolic-ref --short HEAD)
CURRENT_VERSION=$(gh release view --json tagName --jq .tagName || true)
NEXT_VERSION=$(gh semver)
COMMITS=$(git log --color=always --format=" - %C(yellow)%h%Creset %s" "$CURRENT_VERSION...HEAD") # cspell: disable-line

echo ""
echo "Current branch:  $CURRENT_BRANCH"
echo "Current version: $CURRENT_VERSION"
echo -n "Unreleased commits:"
if [[ "$COMMITS" != "" ]]; then
    echo ""
    echo "$COMMITS"
else
    echo " <none>"
fi
echo ""

if [[ "$CURRENT_VERSION" != "$NEXT_VERSION" ]]; then
    echo "Next version: $NEXT_VERSION"
    echo ""
else
    echo "🔴 No commits that would trigger a new release - exiting." 1>&2
    echo ""
    exit 0
fi
