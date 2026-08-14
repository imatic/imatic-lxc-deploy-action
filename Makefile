SHELL := /bin/bash

-include tools/*/include.mk

DOCKER_OPTIONS := --progress=plain --env-file .env.deploy --env-file .env
SERVICE ?=
DOWN_OPTIONS ?=
IMAGE_KEEP_N ?= 1

.PHONY: compose start cleanup

start:
	docker compose $(DOCKER_OPTIONS) pull --include-deps $(SERVICE)
	docker compose $(DOCKER_OPTIONS) down $(DOWN_OPTIONS) $(SERVICE) || true

	source .env.deploy; if [[ -n "$${PROJECT_EXTERNAL_NETWORK:-}" ]]; then \
		docker 2>/dev/null 1>&2 network create --driver bridge $$PROJECT_EXTERNAL_NETWORK || true; \
	fi

	docker compose $(DOCKER_OPTIONS) up -d --no-build --remove-orphans $(SERVICE)

cleanup:
	source .env.deploy && PROJECT_IMAGE=$$PROJECT_IMAGE bin/docker-cleanup.sh $(IMAGE_KEEP_N)

compose:
	docker compose $(DOCKER_OPTIONS) $(filter-out $@,$(MAKECMDGOALS))
