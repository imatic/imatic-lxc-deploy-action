#!/usr/bin/env bash
# Remove versions of images we build (any repository whose name starts with PROJECT_IMAGE,
# e.g. the "-dbtools" variant), keeping the latest plus the IMAGE_KEEP_N previous ones
# (default: 1, i.e. latest + 1 previous). 3rd-party images are left untouched.
# Usage: docker-cleanup.sh [IMAGE_KEEP_N]
# Requires: PROJECT_IMAGE env var (exported from .env.deploy on the deploy host).
set -euo pipefail

: "${PROJECT_IMAGE:?PROJECT_IMAGE env var must be set}"
IMAGE_KEEP_N="${1:-1}"

repos="$(docker images --format '{{.Repository}}' | awk -v prefix="$PROJECT_IMAGE" 'index($0, prefix) == 1' | sort -u)"

while IFS= read -r repo; do
  [[ -z "$repo" ]] && continue

  images="$(docker images --format '{{.CreatedAt}}|{{.Repository}}:{{.Tag}}' "$repo" | grep -v ':<none>$' || true)"
  [[ -z "$images" ]] && continue

  echo "$images" \
    | sort -r \
    | tail -n +"$((IMAGE_KEEP_N + 2))" \
    | cut -d'|' -f2 \
    | xargs -r docker rmi
done <<< "$repos"

docker image prune --force
