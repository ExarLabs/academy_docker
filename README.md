# Academy Docker - Automated Deployment for Academy LMS Stack

This repository provides an automated deployment solution for the Academy LMS stack on Hetzner Cloud. It monitors changes in the application repositories and automatically builds, pushes, and deploys updated Docker images.

## 🎯 Purpose

This is a fork of [frappe/frappe_docker](https://github.com/frappe/frappe_docker) customized to:
- Automatically deploy the Academy LMS stack with custom Frappe apps
- Monitor and react to changes in watched repositories
- Provide CI/CD pipeline for Hetzner deployment
- Integrate AI-powered tutoring capabilities via LangChain

## 📦 Components

The stack includes:

1. **[Academy LMS](https://github.com/ExarLabs/academy-lms)** - Custom fork of Frappe LMS
2. **[Academy AI Tutor Chat](https://github.com/ExarLabs/academy-ai-tutor-chat)** - AI-powered tutoring Frappe app
3. **[Academy LangChain](https://github.com/ExarLabs/academy-LangChain)** - LangChain service for AI functionality
4. **Frappe Framework** - The underlying framework
5. **Supporting Services** - MariaDB, Redis, PostgreSQL, Nginx

## 🚀 I. Quick Start (Local)

### Prerequisites

- GitHub account with access to all repositories
- Git and Docker on you machine

### Basic Setup

0. Use WSL or Linux 
1. Clone this repository 
    - run the next command in terminal: `git clone https://github.com/ExarLabs/academy_docker.git`
2. Create `.env` file in the root folder (check `.env.example` for inspiration)
    - run the next command in terminal: `cp .env.example .env`
    - edit the `.env` file as you want. Note that if you change the `LANGCHAIN_DB_PASSWORD` env variable, you must also change it in the langchain repository's .env file 
3. Run `docker compose up -d`
4. Create a site by running `bash ./scripts/create-site.sh <your_site_name>`
    - your site name must be a valid domain like name (for example academy.local, exar.labs) or an ip (like: 113.23.244.114)
5. Set your site name in your machine's hosts file
    - add the following line to your machine's hosts file
        ```
        127.0.0.1 <your_site_name>
        ```
    - hosts file location on mac / linus: `/etc/hosts/`
    - hosts file location on windows:  `C:\Windows\System32\drivers\etc\hosts`
 6. Type <your_site_name> in your browser


## 🚀 II. Quick Start (CI/CD)

For detailed deployment instructions, see [DEPLOYMENT.md](DEPLOYMENT.md).

### Prerequisites

- GitHub account with access to all repositories
- Hetzner server (Ubuntu 20.04+ recommended)
- GitHub Personal Access Token
- OpenAI API key (for AI features)

### Basic Setup

1. Fork this repository
2. Configure GitHub secrets:
   - `HETZNER_SSH_KEY`
   - `ACADEMY_DOCKER_PAT`
3. Add webhook workflows to watched repositories
4. Run setup script on Hetzner server
5. Configure environment variables
6. Trigger initial deployment

## 🔄 Automated Workflow

```mermaid
graph LR
    A[Code Push] --> B[Webhook Trigger]
    B --> C[Build Docker Image]
    C --> D[Push to GHCR]
    D --> E[Deploy to Hetzner]
    E --> F[Run Migrations]
    F --> G[Health Check]
```

## 📁 Repository Structure

```
academy_docker/
├── .github/workflows/       # CI/CD workflows
│   ├── deploy.yml          # Main deployment workflow
│   └── webhook-*.yml       # Webhook templates for watched repos
├── images/                 # Docker image definitions
│   └── custom/            # Custom Frappe image with apps
├── nginx/                  # Nginx configuration
├── scripts/               # Utility scripts
│   ├── migrate-all-sites.sh
│   └── setup-hetzner.sh
├── compose.yaml           # Docker Compose configuration
├── .env.example          # Environment variables template
└── DEPLOYMENT.md         # Detailed deployment guide
```

## 🔧 Configuration

Key environment variables:

- `MARIADB_ROOT_PASSWORD` - Database root password
- `ADMIN_PASSWORD` - Frappe admin password
- `OPENAI_API_KEY` - OpenAI API key for AI features
- `FRAPPE_SITE_NAME_HEADER` - Your domain name
- `LANGCHAIN_API_URL` - LangChain service URL

## 🛡️ Security

- All secrets stored in GitHub Secrets
- Firewall rules configured automatically
- SSL/TLS support for production
- Regular automated backups

## 📊 Monitoring

- Check service status: `docker compose ps`
- View logs: `docker compose logs -f`
- System health: `docker compose exec backend bench doctor`


# Setup HTTPS for new domains / subdomains
- SSL/TSL security protol is handled by installign `certbot` and `nginx`.
- SSL/TSL certificate is generated and handled by `certbot`. Auto-renewing is enabled by a cronjob
- some nginx configuration (proxying) is create at `/etc/nginx/sites-available/ignis.academy`

## Steps 
1.  update the `/etc/nginx/sites-available/ignis.academy` file by adding the new (sub-)domain to the `server_name` fields
1. run the following command: `sudo certbot --nginx -d already.added.domain1 -d already.added.domain2 ... -d new.domain3`


## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📝 License

This project inherits the license from the original [frappe_docker](https://github.com/frappe/frappe_docker) repository.

## 🆘 Support

- Check [DEPLOYMENT.md](DEPLOYMENT.md) for detailed instructions
- Review GitHub Actions logs for deployment issues
- Open an issue for bugs or feature requests

---

Built with ❤️ for automated Academy LMS deployment
