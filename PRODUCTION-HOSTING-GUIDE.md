# RX-DEX Production Hosting Guide

## Overview

This guide explains how to deploy the RX-DEX platform on a production server (Xeon server) with the domain name toklo.xyz.

## Prerequisites

1. Xeon server with Ubuntu 20.04 LTS or newer
2. Domain name (toklo.xyz) with DNS management access
3. SSL certificate (Let's Encrypt recommended)
4. At least 16GB RAM and 4 CPU cores (recommended for production)
5. Docker and Docker Compose installed

## Server Setup

### 1. Update System

```bash
sudo apt update && sudo apt upgrade -y
```

### 2. Install Docker and Docker Compose

```bash
# Install Docker
sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
sudo apt install docker-ce -y

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Add user to docker group
sudo usermod -aG docker $USER
```

### 3. Install Nginx (Reverse Proxy)

```bash
sudo apt install nginx -y
```

### 4. Install Certbot (SSL Certificate)

```bash
sudo apt install certbot python3-certbot-nginx -y
```

## Project Deployment

### 1. Clone the Repository

```bash
git clone <repository-url> rx-dex
cd rx-dex
```

### 2. Configure Environment Variables

Create a `.env.prod` file:

```bash
# Database
POSTGRES_DB=rxdex
POSTGRES_USER=rxdex
POSTGRES_PASSWORD=your_secure_password_here

# Redis
REDIS_URL=redis://redis:6379

# API Gateway
QUOTER_URL=http://quoter:8081
USER_SERVICE_URL=http://user-service:8084
ORDER_SERVICE_URL=http://order-service:8083
ADMIN_SERVICE_URL=http://admin-service:8088
TRADING_SERVICE_URL=http://trading-service:8089
```

### 3. Update Docker Compose for Production

The project now includes a `docker-compose.prod.yml` file that uses Rust 1.78 to support all contracts and services.

## Domain Configuration

### 1. Configure Nginx

Create `/etc/nginx/sites-available/rx-dex`:

```nginx
server {
    listen 80;
    server_name toklo.xyz www.toklo.xyz;

    location / {
        proxy_pass http://localhost:8082;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # API Gateway
    location /api/ {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/rx-dex /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 2. Obtain SSL Certificate

```bash
sudo certbot --nginx -d toklo.xyz -d www.toklo.xyz
```

## Daily Operations

### 1. Start Services

```bash
# Load environment variables
export $(cat .env.prod) && docker-compose -f docker-compose.prod.yml up -d
```

### 2. Monitor Services

```bash
# Check service status
docker-compose -f docker-compose.prod.yml ps

# View logs
docker-compose -f docker-compose.prod.yml logs -f

# Monitor resource usage
docker stats
```

### 3. Stop Services

```bash
docker-compose -f docker-compose.prod.yml down
```

### 4. Update Services

```bash
# Pull latest code
git pull

# Rebuild and restart services
export $(cat .env.prod) && docker-compose -f docker-compose.prod.yml up -d --build
```

## Security Considerations

### 1. Firewall Configuration

```bash
# Install UFW
sudo apt install ufw -y

# Configure firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw enable
```

### 2. Secure Database

```bash
# Change PostgreSQL password
docker-compose -f docker-compose.prod.yml exec postgres psql -U rxdex -c "ALTER USER rxdex WITH PASSWORD 'new_secure_password';"
```

### 3. Regular Updates

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Update Docker images
docker-compose -f docker-compose.prod.yml pull
```

## Backup Strategy

### 1. Database Backup

```bash
# Create backup script
cat > backup-db.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
docker-compose -f docker-compose.prod.yml exec postgres pg_dump -U rxdex rxdex > backup_$DATE.sql
EOF

chmod +x backup-db.sh
```

### 2. Automated Backups

Add to crontab:

```bash
# Edit crontab
crontab -e

# Add daily backup at 2 AM
0 2 * * * /path/to/rx-dex/backup-db.sh
```

## Monitoring and Logging

### 1. System Monitoring

```bash
# Install monitoring tools
sudo apt install htop iotop iftop -y

# Monitor system resources
htop
iotop
iftop
```

### 2. Docker Monitoring

```bash
# Monitor Docker containers
docker stats

# View container logs
docker-compose -f docker-compose.prod.yml logs -f <service-name>
```

## Scaling for Production

### 1. Horizontal Scaling

To scale specific services:

```bash
# Scale order service to 3 instances
docker-compose -f docker-compose.prod.yml up -d --scale order-service=3
```

### 2. Load Balancing

For high availability, consider using Docker Swarm or Kubernetes.

## Troubleshooting

### Common Issues

1. **Services Not Starting**:
   - Check logs: `docker-compose -f docker-compose.prod.yml logs <service-name>`
   - Verify dependencies are running
   - Check environment variables

2. **Database Connection Issues**:
   - Verify database credentials
   - Check if PostgreSQL is accepting connections
   - Ensure network connectivity between services

3. **Nginx Configuration Issues**:
   - Test configuration: `sudo nginx -t`
   - Check error logs: `sudo tail -f /var/log/nginx/error.log`

4. **SSL Certificate Issues**:
   - Renew certificate: `sudo certbot renew`
   - Check certificate status: `sudo certbot certificates`

### Recovery Procedures

1. **Restore Database from Backup**:
   ```bash
   docker-compose -f docker-compose.prod.yml exec -T postgres psql -U rxdex rxdex < backup_file.sql
   ```

2. **Rollback to Previous Version**:
   ```bash
   git checkout <previous-commit-hash>
   export $(cat .env.prod) && docker-compose -f docker-compose.prod.yml up -d --build
   ```

## Performance Tuning

### 1. Database Optimization

```bash
# Access PostgreSQL
docker-compose -f docker-compose.prod.yml exec postgres psql -U rxdex

# Create indexes
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_trades_pair ON trades(pair);
```

### 2. System Tuning

```bash
# Increase file descriptor limits
echo "* soft nofile 65536" >> /etc/security/limits.conf
echo "* hard nofile 65536" >> /etc/security/limits.conf
```

This guide provides a complete solution for hosting the RX-DEX platform on your Xeon server with the toklo.xyz domain.