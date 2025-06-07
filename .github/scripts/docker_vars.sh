#!/bin/sh
set -eu

: "${DOCKER_NS:?--ns is required}"
: "${DOCKER_REPO:?--repo is required}"
: "${GITHUB_REF:?GITHUB_REF must be set}"
: "${GITHUB_REF_NAME:?GITHUB_REF_NAME must be set}"

echo "DOCKER_NS=${DOCKER_NS}"
echo "DOCKER_REPO=\"${DOCKER_REPO}\""
echo "DOCKER_REPO_PATH=${DOCKER_NS}/${DOCKER_REPO}"

PUSH="false"
TAGS=""
global_suffix="${DOCKER_TAG_SUFFIX:-}"
if printf '%s\n' "$GITHUB_REF" | grep -q '^refs/heads/'; then
    sanitized=$(echo "$GITHUB_REF_NAME" | sed 's/[^a-zA-Z0-9_.-]/-/g')
    TAGS="${sanitized}${global_suffix}"

    # TODO(zrbecker): it's common to set main to latest, but not ideal as this should actually be the latest release tag
    if [ "$GITHUB_REF_NAME" = "main" ]; then
        latest_tag="latest${global_suffix}"
        TAGS="${TAGS},${latest_tag}"
    fi

    PUSH="true"
elif printf '%s\n' "$GITHUB_REF" | grep -q '^refs/tags/'; then
    sanitized=$(echo "$GITHUB_REF_NAME" | sed 's/[^a-zA-Z0-9_.-]/-/g')
    TAGS="${sanitized}${global_suffix}"
    PUSH="true"
else
    TAGS=""
fi
echo "DOCKER_TAGS=${TAGS}"
echo "DOCKER_PUSH=${PUSH}"

REFS=""
if [ -n "$TAGS" ]; then
    OLDIFS=$IFS
    IFS=','
    set -- $TAGS
    IFS=$OLDIFS
    for tag in "$@"; do
        REFS="${REFS:+$REFS,}${DOCKER_NS}/${DOCKER_REPO}:${tag}"
    done
fi
echo "DOCKER_REFS=${REFS}"

TAG_ARGS=""
if [ -n "$REFS" ]; then
    OLDIFS=$IFS
    IFS=','
    set -- $REFS
    IFS=$OLDIFS
    for ref in "$@"; do
        TAG_ARGS="${TAG_ARGS:+$TAG_ARGS }--tag $ref"
    done
fi
echo "DOCKER_TAG_ARGS=${TAG_ARGS}"
