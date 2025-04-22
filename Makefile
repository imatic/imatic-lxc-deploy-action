SHELL := /bin/bash

-include tools/*/include.mk

DOCKER_OPTIONS := --progress=plain --env-file .env.deploy --env-file .env
SERVICE ?= ""

.PHONY: compose start

start:
	docker compose $(DOCKER_OPTIONS) pull --include-deps $(SERVICE)
	docker compose $(DOCKER_OPTIONS) down $(SERVICE) || true

	source .env.deploy; if [[ -n "$${PROJECT_EXTERNAL_NETWORK:-}" ]]; then \
		docker 2>/dev/null 1>&2 network create --driver bridge $$PROJECT_EXTERNAL_NETWORK || true; \
	fi

	docker compose $(DOCKER_OPTIONS) up -d --no-build --remove-orphans $(SERVICE)

	docker 2>/dev/null 1>&2 rmi $(docker images -a) || true

compose:
	docker compose $(DOCKER_OPTIONS) $(filter-out $@,$(MAKECMDGOALS))
