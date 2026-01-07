# Secure Keycloak Deployment Guide

Complete guide to deploy a production-ready Keycloak instance with PostgreSQL backend and SSL-enabled nginx reverse proxy.

## What You'll Get

- Keycloak identity server with PostgreSQL database
- SSL-secured access with Let's Encrypt certificates
- Production-ready nginx reverse proxy
- Health monitoring and metrics collection
- Secure CORS configuration

## Prerequisites

Before starting, ensure you have:

- **Server**: Ubuntu/Debian server with sudo access
- **Domain**: A domain name pointing to your server (e.g., `kc.yourdomain.com`)
- **Docker**: Docker and Docker Compose installed
- **Nginx**: Nginx web server installed
- **Ports**: 80, 443, and 8081 available

## Step 1: Install Dependencies

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Nginx
sudo apt install nginx -y

# Install Certbot for SSL
sudo apt install certbot python3-certbot-nginx -y
```

## Step 2: Get SSL Certificate

Replace `kc.yourdomain.com` with your actual domain:

```bash
# Stop nginx temporarily
sudo systemctl stop nginx

# Get SSL certificate
sudo certbot certonly --standalone -d kc.yourdomain.com

# Start nginx
sudo systemctl start nginx
```

## Step 3: Deploy Keycloak

### Download Configuration Files

```bash
# Create project directory
mkdir ~/keycloak-deploy && cd ~/keycloak-deploy

# Create .env file with your configuration
cat > .env << 'EOF'
# Database Configuration
POSTGRES_DB=keycloakdb
POSTGRES_USER=keycloakuser
POSTGRES_PASSWORD=your-secure-db-password

# Keycloak Configuration
KEYCLOAK_ADMIN_USER=admin
KEYCLOAK_ADMIN_PASSWORD=your-secure-admin-password
KEYCLOAK_HOSTNAME=kc.yourdomain.com
KEYCLOAK_PORT=8081
EOF
```

### Create Docker Compose File

Download this [docker-compose.yml](docker-compose.yml) in your working directory.

### Start Keycloak

```bash
# Deploy the stack
docker compose up -d

# Check if containers are running
docker compose ps

# View logs (optional)
docker compose logs -f keycloak
```

## Step 4: Configure Nginx Reverse Proxy

### Create Nginx Configuration

```bash
# Create nginx config file
sudo tee /etc/nginx/sites-available/keycloak << 'EOF'
upstream keycloak_backend {
    server localhost:8081;
    keepalive 32;
}

map $http_origin $cors_origin {
    default "";
    "https://cloudops.yourdomain.com" $http_origin;
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name kc.yourdomain.com;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://$server_name$request_uri;
    }
}

# HTTPS Server
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name kc.yourdomain.com;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/kc.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/kc.yourdomain.com/privkey.pem;

    # SSL Security Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_session_tickets off;

    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # Logging
    access_log /var/log/nginx/keycloak_access.log;
    error_log /var/log/nginx/keycloak_error.log;

    # Client body size
    client_max_body_size 20M;

    # Timeouts
    proxy_connect_timeout 600s;
    proxy_send_timeout 600s;
    proxy_read_timeout 600s;
    send_timeout 600s;

    # Buffer settings
    proxy_buffer_size 128k;
    proxy_buffers 4 256k;
    proxy_busy_buffers_size 256k;

    location / {
        proxy_pass http://keycloak_backend;
        
        # Proxy headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
        
        # CORS headers
        proxy_hide_header Access-Control-Allow-Origin;
        proxy_hide_header Access-Control-Allow-Credentials;
        proxy_hide_header Access-Control-Allow-Methods;
        proxy_hide_header Access-Control-Allow-Headers;
        
        add_header Access-Control-Allow-Origin $cors_origin always;
        add_header Access-Control-Allow-Credentials true always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Authorization, Content-Type, X-Grafana-Device-Id" always;

        if ($request_method = OPTIONS) {
            return 204;
        }

        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        proxy_buffering off;
        proxy_set_header Connection "";
    }

    # Health check endpoint
    location /health {
        proxy_pass http://keycloak_backend/health;
        proxy_set_header Host $host;
    }
}
EOF
```

### Update Domain Names

Replace all instances of `yourdomain.com` with your actual domain:

```bash
sudo sed -i 's/yourdomain.com/YOURDOMAIN.com/g' /etc/nginx/sites-available/keycloak
```

### Enable Nginx Site

```bash
# Enable the site
sudo ln -s /etc/nginx/sites-available/keycloak /etc/nginx/sites-enabled/

# Test nginx configuration
sudo nginx -t

# Reload nginx
sudo systemctl reload nginx
```

## Step 5: Access Keycloak

### Admin Console

1. Open your browser and go to: `https://kc.yourdomain.com`
2. Click "Administration Console"
3. Login with:
   - **Username**: `admin`
   - **Password**: `admin`

### First Steps After Login

1. **Change admin password**:
   - Go to "Manage" → "Users"
   - Click on "admin" user
   - Go to "Credentials" tab
   - Set a strong password

2. **Create a realm**:
   - Click dropdown next to "Master" realm
   - Click "Create Realm"
   - Enter realm name and create

## Step 6: Security Hardening

### Firewall Configuration

```bash
# Allow only necessary ports
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable
```

## Monitoring & Maintenance

### Health Checks

```bash
# Check container status
docker compose ps

# Check Keycloak health
curl -k https://kc.yourdomain.com/health

# View logs
docker compose logs -f keycloak
```

### Backup

```bash
# Create backup script
cat > ~/backup-keycloak.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/backup/keycloak/$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR

# Backup database
docker exec kcdb pg_dump -U keycloakuser keycloakdb > $BACKUP_DIR/keycloak_db.sql

# Backup docker volumes
sudo cp -r /var/lib/docker/volumes/keycloak-deploy_postgres-data $BACKUP_DIR/

echo "Backup completed: $BACKUP_DIR"
EOF

chmod +x ~/backup-keycloak.sh
```

### Updates

```bash
# Update Keycloak
cd ~/keycloak-deploy
docker compose pull
docker compose up -d

# Clean up old images
docker image prune -f
```

## Troubleshooting

### Common Issues

1. **"502 Bad Gateway"**:

   ```bash
   # Check if Keycloak is running
   docker compose ps
   # Check logs
   docker compose logs keycloak
   ```

2. **SSL Certificate Issues**:

   ```bash
   # Renew certificate
   sudo certbot renew
   sudo systemctl reload nginx
   ```

3. **Database Connection Issues**:

   ```bash
   # Check PostgreSQL logs
   docker compose logs postgres
   ```

### Useful Commands

```bash
# Restart services
docker compose restart

# View all logs
docker compose logs

# Check nginx status
sudo systemctl status nginx

# Test nginx config
sudo nginx -t
```

## Next Steps

- Configure realms and clients for your applications
- Set up user federation (LDAP/Active Directory)
- Configure social login providers
- Set up themes and branding
- Configure backup automation

Your Keycloak instance is now securely deployed and ready for production use!
