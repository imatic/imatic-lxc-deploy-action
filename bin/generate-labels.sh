#!/usr/bin/env bash
set -euo pipefail

# Required env vars: APP_SERVERS, LABELS_TARGET, PROXY_PASS_PORT, DOCKER_COMPOSE_FILE, YQ
# Optional env var:  LABELS_FILE (path where generated labels YAML is written; defaults to a temp file)

labels_file="${LABELS_FILE:-$(mktemp)}"

printf "labels:\n" > "$labels_file"
read -ra servers <<< "$APP_SERVERS"
for i in "${!servers[@]}"; do
  n=$((i + 1))
  printf "  imatic.server.serv%d.server_name: '%s'\n" "$n" "${servers[$i]}" >> "$labels_file"
  printf "  imatic.server.serv%d.location.loc1.name: '/'\n" "$n" >> "$labels_file"
  printf "  imatic.server.serv%d.location.loc1.block.proxy_pass.port: %s\n" "$n" "$PROXY_PASS_PORT" >> "$labels_file"
  printf "  imatic.server.serv%d.location.loc1.block.proxy_pass.protocol: 'http'\n" "$n" >> "$labels_file"
done
"$YQ" -i \
  ".services.${LABELS_TARGET}.labels = load(\"$labels_file\").labels" \
  "$DOCKER_COMPOSE_FILE"
