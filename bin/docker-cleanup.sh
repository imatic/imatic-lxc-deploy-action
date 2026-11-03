#!/usr/bin/env bash
# Remove versions of images we build (any repository whose name starts with PROJECT_IMAGE,
# e.g. the "-dbtools" variant), keeping only the IMAGE_KEEP_N most recent ones (default: 1).
# Meant to run before pulling the new version, so after the pull the server holds the deployed
# version plus IMAGE_KEEP_N previous ones. Images used by any container (e.g. the running one
# after a rollback to an older version) are always kept. 3rd-party images are left untouched.
# Usage: docker-cleanup.sh [IMAGE_KEEP_N]
# Requires: PROJECT_IMAGE env var (exported from .env.deploy on the deploy host).
set -euo pipefail

: "${PROJECT_IMAGE:?PROJECT_IMAGE env var must be set}"
IMAGE_KEEP_N="${1:-1}"

repos="$(docker images --format '{{.Repository}}' | awk -v prefix="$PROJECT_IMAGE" 'index($0, prefix) == 1' | sort -u)"
used_ids="$(docker ps -aq | xargs -r docker inspect --format '{{.Image}}' | sort -u)"

while IFS= read -r repo; do
  [[ -z "$repo" ]] && continue

  images="$(docker images --no-trunc --format '{{.CreatedAt}}|{{.Repository}}:{{.Tag}}|{{.ID}}' "$repo" | grep -v ':<none>|' || true)"
  [[ -z "$images" ]] && continue

  old="$(echo "$images" \
    | sort -r \
    | tail -n +"$((IMAGE_KEEP_N + 1))" \
    | cut -d'|' -f2-)"
  [[ -z "$old" ]] && continue

  while IFS='|' read -r image id; do
    if grep -qxF "$id" <<< "$used_ids"; then
      echo "Keeping image used by a container: $image"
      continue
    fi
    echo "Removing image: $image"
    docker rmi "$image" > /dev/null || echo "Failed to remove image: $image"
  done <<< "$old"
done <<< "$repos"

docker image prune --force
