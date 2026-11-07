# Installing Traefik · Docker Deployment

**Traefik v3 + Docker Compose · Ubuntu/Linux · HTTPS (ACME / Let's Encrypt) · Install under `/opt`**

This repository contains a Docker Compose-based Traefik setup and related stack files.
The recommended production install location on Ubuntu/Linux is **`/opt/traefik`** (or
`/opt/<your-deployment-name>`), not a user home directory. Installing under `/opt`
keeps service files in a standard system path, simplifies permissions, backups, and
service management.

> The main [`docker-compose.yml`](docker-compose.yml) in this repository may include
> additional services beyond Traefik. Review it before deploying and remove or disable
> services you do not need. Use [`ai-stack-compose.yml`](ai-stack-compose.yml) only if
> you intentionally deploy that stack.

## Contents

1. [Overview](#overview)
2. [Requirements](#requirements)
3. [Install Path (`/opt`)](#install-path-opt)
4. [Quick Start](#quick-start)
5. [Configuration](#configuration)
6. [Traefik Files and ACME Storage](#traefik-files-and-acme-storage)
7. [Operations](#operations)
8. [Security Checklist](#security-checklist)
9. [Troubleshooting](#troubleshooting)

## Overview

Traefik acts as a reverse proxy for Docker containers. It watches Docker labels,
routes HTTP/HTTPS traffic to backend services, and can obtain TLS certificates
through ACME/Let's Encrypt when DNS/provider settings are configured.

| Component | Purpose |
|---|---|
| Traefik | Reverse proxy, routing, TLS termination, dashboard/API (protect it) |
| Docker socket (`/var/run/docker.sock`) | Service discovery (read-only mount recommended) |
| `proxy` network | Shared external Docker network for proxied services |
| ACME storage (`acme.json`) | Stores Let's Encrypt certificates/credentials |

## Requirements

- Ubuntu 22.04/24.04 or a compatible Linux server.
- Docker Engine.
- Docker Compose v2 (`docker compose`).
- A public DNS name pointing to the server for HTTPS/ACME (if using Let's Encrypt).
- Ports `80` and `443` available on the host. Port `8080` should not be exposed
  publicly unless intentionally protected.

Verify:

```bash
docker --version
sudo docker compose version
sudo ss -tulpn | grep -E ':80|:443|:8080' || true
```

## Install Path (`/opt`)

Use `/opt` as the deployment root:

```text
/opt/traefik/
├── .env                          # Local secrets/config (do not commit)
├── docker-compose.yml            # Deployment compose file (review before use)
├── traefik/
│   ├── traefik.yml               # Optional static config (if used)
│   ├── acme.json                 # ACME storage, chmod 600
│   ├── certs/                    # Optional local certs
│   └── dynamic/                  # Dynamic/file provider config
└── shared/                       # Optional shared files (e.g. .htpasswd)
```

Why `/opt`:

- Standard location for optional/add-on software on Linux.
- Predictable path for backups, cron jobs, monitoring, and runbooks.
- Avoids accidental edits in a developer home directory.
- Easier to apply restrictive permissions to service secrets.

## Quick Start

### 1. Prepare `/opt` and clone the repository

```bash
sudo mkdir -p /opt/traefik
sudo chown "$USER":"$USER" /opt/traefik
git clone https://github.com/abdalazeim/InstallingTraefik-Docker-Deployment.git /opt/traefik
cd /opt/traefik
```

If you already have the files locally, copy them to `/opt/traefik` and review them:

```bash
sudo mkdir -p /opt/traefik
sudo rsync -a --exclude '.git' ./ /opt/traefik/
sudo chown -R "$USER":"$USER" /opt/traefik
cd /opt/traefik
```

### 2. Create environment file

```bash
cd /opt/traefik
cp .env.example .env
chmod 600 .env
```

Edit `.env` and set real values (API tokens, email, domain-related variables used by
your compose/Traefik config). Never commit `.env`.

### 3. Prepare Traefik directories and ACME file

```bash
cd /opt/traefik
mkdir -p traefik/certs traefik/dynamic shared
touch traefik/acme.json
chmod 600 traefik/acme.json
chmod 700 traefik
```

If you use basic auth for dashboards, create the password file with restrictive
permissions:

```bash
# Example: create/update shared/.htpasswd (requires apache2-utils or htpasswd)
# htpasswd -nbB admin 'STRONG_PASSWORD' | sudo tee /opt/traefik/shared/.htpasswd >/dev/null
# sudo chmod 600 /opt/traefik/shared/.htpasswd
```

### 4. Create the external Docker network

Services that should be routed by Traefik usually attach to a shared external
network:

```bash
sudo docker network create proxy || true
```

Use the same network name in service labels and Compose files (`proxy` by default in
many setups).

### 5. Review and start

Before starting, review [`docker-compose.yml`](docker-compose.yml):

- Remove services you do not need.
- Replace example domains/emails/tokens.
- Ensure dashboard/API is not publicly exposed without authentication.
- Confirm volume paths are correct for `/opt/traefik`.

Then start:

```bash
cd /opt/traefik
sudo docker compose pull
sudo docker compose up -d
sudo docker compose ps
```

## Configuration

Key areas to review:

| Area | What to check |
|---|---|
| `.env` | Secrets, ACME/DNS provider tokens, timezone, PUID/PGID if used |
| `docker-compose.yml` | Services, ports, labels, domains, networks, volumes |
| `traefik/acme.json` | Must exist and be `600` before starting ACME |
| `traefik/dynamic/` | TLS/options/middleware files loaded by file provider |
| `shared/` | Optional auth files and shared assets |

DNS/ACME: for Let's Encrypt DNS challenges, the DNS provider token must have the
permissions required by Traefik's resolver and the domains must resolve correctly.

## Traefik Files and ACME Storage

`acme.json` stores certificate material. Treat it as sensitive:

```bash
cd /opt/traefik
ls -l traefik/acme.json
# expected: -rw------- ... acme.json
```

If permissions are too open, Traefik may refuse to use it.

## Operations

Run commands from `/opt/traefik`:

```bash
cd /opt/traefik
sudo docker compose ps
sudo docker compose logs -f traefik
sudo docker compose pull
sudo docker compose up -d
sudo docker compose restart traefik
sudo docker compose down
```

Back up at minimum:

- `/opt/traefik/.env` (securely)
- `/opt/traefik/docker-compose.yml` and Traefik config files
- `/opt/traefik/traefik/acme.json` (securely)
- any dynamic config and auth files

## Security Checklist

- [ ] Install under `/opt/traefik` (or a clear `/opt/<name>` path).
- [ ] Keep `.env`, `acme.json`, and auth files out of Git.
- [ ] Set `chmod 600` on `.env`, `acme.json`, and auth files.
- [ ] Do not expose Traefik dashboard/API publicly without strong authentication.
- [ ] Mount Docker socket read-only where possible (`/var/run/docker.sock:ro`).
- [ ] Review all services in `docker-compose.yml`; deploy only what you need.
- [ ] Replace example domains, emails, and credentials.
- [ ] Keep Docker Engine, Traefik, and images updated.

## Troubleshooting

| Symptom | Check |
|---|---|
| Port 80/443 already in use | `sudo ss -tulpn | grep -E ':80|:443'`; stop conflicting service or change bindings |
| Certificate not issued | Traefik logs, DNS records, ACME resolver config, provider token permissions, `acme.json` permissions |
| Dashboard not reachable | Router rules, entrypoints, auth middleware, firewall/security group, whether port 8080 is intended |
| Backend not routed | Container on `proxy` network, `traefik.enable=true`, correct router rule/service port labels |
| Permission denied on files | Ownership under `/opt/traefik` and `chmod 600` for secrets |

Useful commands:

```bash
cd /opt/traefik
sudo docker compose logs --tail=200 traefik
sudo docker network inspect proxy
sudo docker compose config
```
