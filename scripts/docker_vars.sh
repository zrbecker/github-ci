#!/bin/sh
set -eu

while [ "$#" -gt 0 ]; do
    case "$1" in
    --ns)
        DOCKER_NS="$2"
        shift 2
        ;;
    --repo)
        DOCKER_REPO="$2"
        shift 2
        ;;
    *)
        echo "Unknown option: $1" >&2
        exit 1
        ;;
    esac
done

: "${DOCKER_NS:?--ns is required}"
: "${DOCKER_REPO:?--repo is required}"
: "${GITHUB_REF:?GITHUB_REF must be set}"
: "${GITHUB_REF_NAME:?GITHUB_REF_NAME must be set}"

echo "DOCKER_NS=${DOCKER_NS}"
echo "DOCKER_REPO=\"${DOCKER_REPO}\""

TAGS=""
global_prefix="${DOCKER_TAG_PREFIX:-}"
global_suffix="${DOCKER_TAG_SUFFIX:-}"
if printf '%s\n' "$GITHUB_REF" | grep -q '^refs/heads/'; then
    sanitized=$(echo "$GITHUB_REF_NAME" | sed 's/[^a-zA-Z0-9_.-]/-/g')
    branch_prefix="${DOCKER_TAG_BRANCH_PREFIX:-}"
    branch_suffix="${DOCKER_TAG_BRANCH_SUFFIX:-}"

    base_tag="${branch_prefix}${sanitized}${branch_suffix}"
    full_tag="${global_prefix}${base_tag}${global_suffix}"
    TAGS="$full_tag"

    # TODO(zrbecker): it's common to set main to latest, but not ideal as this should actually be the latest release tag
    if [ "$GITHUB_REF_NAME" = "main" ]; then
        latest_tag="${global_prefix}latest${global_suffix}"
        TAGS="${TAGS},${latest_tag}"
    fi
elif printf '%s\n' "$GITHUB_REF" | grep -q '^refs/tags/'; then
    sanitized=$(echo "$GITHUB_REF_NAME" | sed 's/[^a-zA-Z0-9_.-]/-/g')
    TAGS="${global_prefix}${sanitized}${global_suffix}"
else
    TAGS=""
fi
echo "DOCKER_TAGS=${TAGS}"

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
