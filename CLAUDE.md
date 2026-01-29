# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Academy Docker is a Docker-based automated deployment solution for the Academy LMS stack on Hetzner Cloud. It's a customized fork of [frappe/frappe_docker](https://github.com/frappe/frappe_docker) that deploys:

- **Academy LMS** - Custom fork of Frappe LMS (ExarLabs/academy-lms)
- **Academy LangChain** - LangChain service for AI functionality (ExarLabs/academy-LangChain)

## Architecture

### Docker Services

The stack runs via `compose.yaml` with two isolated networks:

**frappe-network:**
- `mariadb` - MariaDB 10.8 database for Frappe
- `redis` - Shared cache/queue between Frappe and LangChain
- `backend` - Frappe/Gunicorn server (port 8000)
- `frontend` - Nginx reverse proxy (port 8080)
- `websocket` - Socket.io for real-time features (port 9000)
- `queue-short`, `queue-long` - Background job workers
- `scheduler` - Frappe task scheduler
- `configurator` - One-time bench configuration

**langchain-network:**
- `postgres` - PostgreSQL 15 for LangChain
- `langchain-service` - FastAPI AI service (exposed on port 8001)
- `langchain-db-init` - One-time database table creation

Redis bridges both networks for LMS-LangChain communication.

### Key Integration

The LMS communicates with LangChain via Redis pub/sub. This is enabled during site creation with:
```bash
bench --site <site> set-config langchain_use_redis true
```

## Common Commands

### Local Development

```bash
# Start all services
docker compose up -d

# Create a new site (site name must be domain-like: academy.local, 192.168.1.1)
bash ./scripts/create-site.sh <site-name>

# Run migrations on all sites
bash ./scripts/migrate-all-sites.sh

# View logs
docker compose logs -f <service>

# Stop services
docker compose down
```

### Frappe Bench Commands

```bash
# Run via docker compose exec
docker compose exec backend bench --site <site> migrate
docker compose exec backend bench --site <site> clear-cache
docker compose exec backend bench --site <site> install-app <app>
docker compose exec backend bench doctor
docker compose exec backend bench --site <site> backup
docker compose exec backend bench use <site>
```

### Building Images

```bash
# Build custom Frappe image with Docker BuildX
docker buildx bake -f docker-bake.hcl erpnext

# Direct Docker build
docker build -f images/custom/Containerfile \
  --build-arg LMS_REPO_URL=https://github.com/ExarLabs/academy-lms \
  -t academy-lms:latest .
```

## GitHub Actions Workflows

| Workflow | Purpose |
|----------|---------|
| `deploy.yml` | Main CI/CD: builds images, pushes to GHCR, deploys to Hetzner |
| `create-site.yml` | Create new Frappe sites on production |
| `remove-site.yml` | Remove sites and archive data |
| `restore-site.yml` | Restore sites from backups |
| `lint.yml` | Pre-commit code quality checks |

Deploy triggers: push to master, webhook from watched repos, manual dispatch.

## Environment Configuration

Copy `.env.example` to `.env` and configure:

**Required:**
- `MARIADB_ROOT_PASSWORD` - MariaDB root password
- `ADMIN_PASSWORD` - Frappe Administrator password
- `OPENAI_API_KEY` - For AI features
- `LANGCHAIN_DB_PASSWORD` - PostgreSQL password (must match langchain repo's .env)

**LangChain service URL** defaults to `http://langchain-service:8000` via `AI_TUTOR_API_URL`.

## Production Deployment (Hetzner)

- Server: 188.245.211.114
- Deploy path: `/opt/frappe-deployment`
- User: `ignis_academy_lms`
- SSL handled by certbot + nginx at `/etc/nginx/sites-available/ignis.academy`

To add new domains for HTTPS:
1. Update `/etc/nginx/sites-available/ignis.academy` with the new domain in `server_name`
2. Run: `sudo certbot --nginx -d existing.domain -d new.domain`
