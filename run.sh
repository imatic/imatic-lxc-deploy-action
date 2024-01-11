#!/bin/bash

# This file is generated by Imatic LXC Deploy action and should not be edited manually.

set -eu pipefail

cd "$(dirname "$0")"

source .env.deploy

ENV_FILES="--env-file .env.deploy --env-file .env"

docker compose ${ENV_FILES} pull

docker compose ${ENV_FILES} down || true

if [[ -n "${PROJECT_EXTERNAL_NETWORK:-}" ]]; then
    docker 2>/dev/null 1>&2 network create --driver bridge $PROJECT_EXTERNAL_NETWORK || true
fi

docker compose ${ENV_FILES} up -d --no-build --remove-orphans

# remove all unused images
2>/dev/null 1>&2 docker rmi $(docker images -a) || true
