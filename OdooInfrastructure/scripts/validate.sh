#!/usr/bin/env bash
# Validate compose files (run on a host with Docker Compose v2 installed).
# Usage: ./scripts/validate.sh  (from OdooInfrastructure root)
set -euo pipefail
cd "$(dirname "$0")/.."
echo "== Traefik =="
docker compose -f docker-compose.traefik.yml config >/dev/null && echo "OK: docker-compose.traefik.yml"
echo "== Odoo 17 =="
docker compose --env-file .env.example -f odoo17/docker-compose.yml config >/dev/null && echo "OK: odoo17/docker-compose.yml"
echo "== Odoo 19 =="
docker compose --env-file .env.example -f odoo19/docker-compose.yml config >/dev/null && echo "OK: odoo19/docker-compose.yml"
