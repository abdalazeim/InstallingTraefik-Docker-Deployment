#!/usr/bin/env bash
# Example backup helper (run on Docker host, from OdooInfrastructure root).
# Review and adapt paths/names before production use. Test restore.
set -euo pipefail
TS="$(date +%Y%m%d_%H%M%S)"
OUT="${1:-./backups}"
mkdir -p "$OUT"

echo "Backing up Odoo 17 DB (container odoo17-db, user from env - edit as needed)..."
# docker exec odoo17-db pg_dumpall -U "$ODOO17_DB_USER" > "$OUT/odoo17_pg_${TS}.sql"

echo "Backing up Odoo 19 DB..."
# docker exec odoo19-db pg_dumpall -U "$ODOO19_DB_USER" > "$OUT/odoo19_pg_${TS}.sql"

echo "Backing up filestore volumes (example using temporary containers)..."
# docker run --rm -v odoo17_filestore:/data -v "$(pwd)/$OUT:/backup" alpine tar czf "/backup/odoo17_filestore_${TS}.tgz" -C /data .
# docker run --rm -v odoo19_filestore:/data -v "$(pwd)/$OUT:/backup" alpine tar czf "/backup/odoo19_filestore_${TS}.tgz" -C /data .

echo "Also back up: .env (securely), traefik/acme/acme.json (securely), compose/config files."
