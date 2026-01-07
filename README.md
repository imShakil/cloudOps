# cloudOps

Comprehensive cloud operations infrastructure with identity management, monitoring, and observability.

## Components

- **[Keycloak](keycloak/)**: Identity and access management with PostgreSQL
- **[Monitoring](monitoring/)**: Prometheus, Grafana, AlertManager, Loki, Tempo
- **[Nginx](nginx/)**: SSL reverse proxy configurations

## Quick Start

```bash
# Deploy Keycloak
cd keycloak && docker-compose up -d

# Deploy Monitoring
cd monitoring && docker-compose up -d

# Configure Nginx
sudo cp nginx/*.conf /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites-available/cloudops.conf /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/keycloak.conf /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

## Access URLs

- **Grafana**: https://cloudops.mhosen.com
- **Keycloak**: https://kc.mhosen.com
- **AlertManager**: https://cloudops.mhosen.com/am
- **Prometheus**: https://cloudops.mhosen.com/prometheus

## Prerequisites

- Docker & Docker Compose
- Nginx web server
- SSL certificates (Let's Encrypt)
- Configured domains