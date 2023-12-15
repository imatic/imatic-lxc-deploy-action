#!/bin/bash
set -eu pipefail

cd "$(dirname "$0")"

docker compose pull

docker compose down || true

docker compose --env-file .env up -d --no-build

# remove all unused images
2>/dev/null 1>&2 docker rmi $(docker images -a) || true
