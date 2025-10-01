# RX-DEX Production Deployment Guide for Xeon Server

## Overview

This guide provides step-by-step instructions for deploying the RX-DEX platform on your Xeon server for production use with the toklo.xyz domain.

## Prerequisites

1. Xeon server with Ubuntu 20.04 LTS or newer
2. At least 16GB RAM and 4 CPU cores
3. Root access to the server
4. Domain name (toklo.xyz) with DNS management access
5. GitHub account with access to the RX-DEX repository

## Server Preparation

### 1. Initial Server Setup

First, ensure your server is up to date:

```bash
sudo apt update && sudo apt upgrade -y
```

### 2. Run the Automated Setup Script

The RX-DEX project includes an automated setup script that will install all required dependencies:

```bash
# Clone the repository
git clone https://github.com/attakdefand/rx-dex.git
cd rx-dex

# Run the setup script
sudo ./scripts/setup-prod.sh
```

This script will:
- Install Docker and Docker Compose
- Install Nginx (reverse proxy)
- Install Certbot (SSL certificates)
- Configure the firewall
- Create necessary directories

### 3. Post-Installation Steps

After the setup script completes:
1. Log out and log back in to apply Docker group membership
2. Verify Docker is working:
   ```bash
   docker --version
   docker-compose --version
   ```

## Configuration

### 1. Create Production Environment File

Create a `.env.prod` file in the project root with your production settings:

```bash
# Database Configuration
POSTGRES_DB=rxdex
POSTGRES_USER=rxdex
POSTGRES_PASSWORD=your_secure_password_here

# Redis Configuration
REDIS_URL=redis://redis:6379

# Service URLs (used by API Gateway)
QUOTER_URL=http://quoter:8081
USER_SERVICE_URL=http://user-service:8084
ORDER_SERVICE_URL=http://order-service:8083
ADMIN_SERVICE_URL=http://admin-service:8088
TRADING_SERVICE_URL=http://trading-service:8089
```

> ⚠️ **Security Note**: Use strong, unique passwords and consider using a password manager to generate and store them securely.

### 2. Configure Domain DNS

Before proceeding, configure your domain DNS settings with GoDaddy:

1. Log in to your GoDaddy account
2. Navigate to the DNS management page for toklo.xyz
3. Add the following A records:
   - Host: @ → Points to: [Your Server's IP Address]
   - Host: www → Points to: [Your Server's IP Address]

Wait for DNS propagation (this can take up to 48 hours, but is usually much faster).

## Deployment

### 1. Configure Nginx

Create the Nginx configuration file:

```bash
sudo nano /etc/nginx/sites-available/rx-dex
```

Add the following configuration:

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

Once DNS has propagated, obtain an SSL certificate:

```bash
sudo certbot --nginx -d toklo.xyz -d www.toklo.xyz
```

### 3. Start Services

Use the daily operations script to start all services:

```bash
./scripts/daily-prod.sh start
```

This command will:
- Load environment variables from `.env.prod`
- Start all services in detached mode using Docker Compose

### 4. Verify Deployment

Check that all services are running:

```bash
./scripts/daily-prod.sh status
```

You should see all services in the "Up" state.

## Daily Operations

### Starting Services

```bash
./scripts/daily-prod.sh start
```

### Stopping Services

```bash
./scripts/daily-prod.sh stop
```

### Restarting Services

```bash
./scripts/daily-prod.sh restart
```

### Checking Service Status

```bash
./scripts/daily-prod.sh status
```

### Viewing Logs

```bash
./scripts/daily-prod.sh logs
```

### Updating Services

To update to the latest version:

```bash
./scripts/daily-prod.sh update
```

This will:
- Pull the latest code from the repository
- Rebuild and restart all services

### Creating Database Backups

```bash
./scripts/daily-prod.sh backup
```

Backups will be created in the project root with a timestamp.

## Monitoring

### Service Monitoring

```bash
./scripts/daily-prod.sh monitor
```

This will show real-time resource usage for all containers.

### System Monitoring

Install additional monitoring tools:

```bash
sudo apt install htop iotop iftop -y
```

Then use:
- `htop` - CPU and memory usage
- `iotop` - Disk I/O usage
- `iftop` - Network usage

## Security Considerations

### Firewall Configuration

The setup script configures UFW with basic rules. You can check the status with:

```bash
sudo ufw status
```

### Secure Database

To change the PostgreSQL password after deployment:

```bash
./scripts/daily-prod.sh stop
# Edit .env.prod with new password
./scripts/daily-prod.sh start
```

### Regular Updates

Regularly update your system and Docker images:

```bash
sudo apt update && sudo apt upgrade -y
docker-compose -f docker-compose.prod.yml pull
./scripts/daily-prod.sh restart
```

## Scaling for Production

### Horizontal Scaling

To scale specific services (e.g., order-service to 3 instances):

```bash
docker-compose -f docker-compose.prod.yml up -d --scale order-service=3
```

### Load Balancing

For high availability, consider using Docker Swarm or Kubernetes for production environments with heavy traffic.

## Troubleshooting

### Common Issues

1. **Services Not Starting**:
   - Check logs: `./scripts/daily-prod.sh logs`
   - Verify dependencies are running: `./scripts/daily-prod.sh status`
   - Check environment variables in `.env.prod`

2. **Database Connection Issues**:
   - Verify database credentials in `.env.prod`
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
   ./scripts/daily-prod.sh update
   ```

## Performance Tuning

### Database Optimization

Access PostgreSQL to create indexes for better performance:

```bash
docker-compose -f docker-compose.prod.yml exec postgres psql -U rxdex
```

Then create indexes:
```sql
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_trades_pair ON trades(pair);
```

### System Tuning

Increase file descriptor limits for better performance:

```bash
echo "* soft nofile 65536" >> /etc/security/limits.conf
echo "* hard nofile 65536" >> /etc/security/limits.conf
```

## Accessing Your Deployment

Once everything is set up, you can access your RX-DEX platform at:
- Web Interface: https://toklo.xyz
- API Gateway: https://toklo.xyz/api/

## Conclusion

Your RX-DEX platform is now deployed on your Xeon server with:
- All microservices running in Docker containers
- SSL encryption via Let's Encrypt
- Nginx reverse proxy for efficient request handling
- Automated daily operations scripts for easy management
- Security best practices implemented

For ongoing maintenance, refer to the [PRODUCTION-HOSTING-GUIDE.md](file:///c%3A/Users/RMT/Documents/vscodium/crypto-Exchange-Rust-Base/RX-DEX/rx-dex/PRODUCTION-HOSTING-GUIDE.md) and [DAILY-OPERATIONS-GUIDE.md](file:///c%3A/Users/RMT/Documents/vscodium/crypto-Exchange-Rust-Base/RX-DEX/rx-dex/DAILY-OPERATIONS-GUIDE.md) files in your repository.