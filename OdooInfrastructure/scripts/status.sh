#!/usr/bin/env bash
# Show status (run on Docker host). Does not expose secrets.
set -euo pipefail
echo "=== Containers ==="
docker ps -a --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' | head -n 40 || true
echo
echo "=== proxy network ==="
docker network inspect proxy --format '{{.Name}}: {{range .Containers}}{{.Name}} {{end}}' 2>/dev/null || echo "proxy network not found"
echo
echo "=== Volumes (odoo/traefik related) ==="
docker volume ls --format '{{.Name}}' | grep -E 'odoo17|odoo19|traefik' || true
