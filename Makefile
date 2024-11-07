-include include/*

DOCKER_OPTIONS := --progress=plain --env-file .env.deploy --env-file .env

.PHONY: compose start

start:
	source .env.deploy

	docker compose $(DOCKER_OPTIONS) pull
	docker compose $(DOCKER_OPTIONS) down || true

	if [[ -n "${PROJECT_EXTERNAL_NETWORK:-}" ]]; then
	    docker 2>/dev/null 1>&2 network create --driver bridge $PROJECT_EXTERNAL_NETWORK || true
	fi

	docker compose $(DOCKER_OPTIONS) up -d --no-build --remove-orphans

	docker 2>/dev/null 1>&2 rmi $(docker images -a) || true

compose:
	docker compose $(ENV_FILES) $(filter-out $@,$(MAKECMDGOALS))