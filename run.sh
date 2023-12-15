#!/bin/bash
set -eu pipefail

cd "$(dirname "$0")"

ENV_FILES="--env-file .env.deploy --env-file .env"

docker compose ${ENV_FILES} pull

docker compose ${ENV_FILES} down || true

docker compose ${ENV_FILES} up -d --no-build --remove-orphans

# remove all unused images
2>/dev/null 1>&2 docker rmi $(docker images -a) || true
