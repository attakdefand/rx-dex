# RX-DEX Daily Operations Guide

## Overview

This guide provides instructions for daily operations of the RX-DEX platform in a production environment on your Xeon server with the domain name toklo.xyz.

## Prerequisites

1. SSH access to your Xeon server
2. RX-DEX project deployed as per the PRODUCTION-HOSTING-GUIDE.md
3. All required environment variables configured in `.env.prod`
4. Docker and Docker Compose installed and configured

## Daily Operations Checklist

### 1. Morning Check (9:00 AM)

#### a. Service Status Verification
```bash
# Using the daily operations script
./scripts/daily-prod.sh status

# Or manually
docker-compose -f docker-compose.prod.yml ps
```

#### b. System Health Check
```bash
# Using the monitoring script
./scripts/monitor-prod.sh report

# Or manually check system resources
htop
df -h
```

#### c. Log Review
```bash
# Check for errors in the last 24 hours
./scripts/monitor-prod.sh logs

# Or manually
docker-compose -f docker-compose.prod.yml logs --since=24h | grep -i "error\|warn\|fail"
```

### 2. Midday Check (12:00 PM)

#### a. API Health Verification
```bash
# Check API gateway health
curl -f http://localhost:8080/health

# Check web frontend
curl -f http://localhost:8082

# Or using the monitoring script
./scripts/monitor-prod.sh api
```

#### b. Database and Redis Status
```bash
# Using the monitoring script
./scripts/monitor-prod.sh database
./scripts/monitor-prod.sh redis

# Or manually
docker-compose -f docker-compose.prod.yml exec postgres pg_isready
docker-compose -f docker-compose.prod.yml exec redis redis-cli ping
```

### 3. Evening Check (6:00 PM)

#### a. Resource Usage Review
```bash
# Using the monitoring script
./scripts/monitor-prod.sh resources

# Or manually
docker stats --no-stream
```

#### b. Backup Verification
```bash
# Check if daily backup exists
ls -la backup_*.sql

# Verify backup integrity (simplified)
head -n 20 backup_*.sql
```

## Weekly Operations

### 1. Weekly Backup (Sunday 2:00 AM)

#### a. Database Backup
```bash
# Using the daily operations script
./scripts/daily-prod.sh backup

# Or manually
DATE=$(date +%Y%m%d_%H%M%S)
docker-compose -f docker-compose.prod.yml exec postgres pg_dump -U $POSTGRES_USER $POSTGRES_DB > backup_$DATE.sql
```

#### b. System Backup
```bash
# Backup important configuration files
tar -czf config_backup_$(date +%Y%m%d).tar.gz .env.prod docker-compose.prod.yml nginx.conf
```

### 2. Weekly Update (Sunday 3:00 AM)

#### a. Code Update
```bash
# Using the daily operations script
./scripts/daily-prod.sh update

# Or manually
git pull
docker-compose -f docker-compose.prod.yml up -d --build
```

#### b. System Update
```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Update Docker images
docker-compose -f docker-compose.prod.yml pull
```

## Monthly Operations

### 1. Security Audit

#### a. SSL Certificate Renewal
```bash
# Check certificate expiration
sudo certbot certificates

# Renew if needed
sudo certbot renew
```

#### b. System Security Check
```bash
# Check for security updates
sudo apt list --upgradable | grep -i security

# Run security audit tools
sudo lynis audit system
```

### 2. Performance Review

#### a. Database Optimization
```bash
# Analyze and optimize database
docker-compose -f docker-compose.prod.yml exec postgres psql -U $POSTGRES_USER $POSTGRES_DB -c "ANALYZE;"
```

#### b. Log Analysis
```bash
# Analyze logs for performance issues
# This would typically involve more sophisticated log analysis tools
docker-compose -f docker-compose.prod.yml logs --since=30d > monthly_logs.txt
```

## Emergency Procedures

### 1. Service Restart
```bash
# Using the daily operations script
./scripts/daily-prod.sh restart

# Or manually
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d
```

### 2. Database Recovery
```bash
# Restore from backup
docker-compose -f docker-compose.prod.yml exec -T postgres psql -U $POSTGRES_USER $POSTGRES_DB < backup_file.sql
```

### 3. Rollback to Previous Version
```bash
# If using git for version control
git checkout <previous-stable-commit>
docker-compose -f docker-compose.prod.yml up -d --build
```

## Monitoring Alerts

### 1. Critical Alerts
- Service downtime
- Database connection failures
- High CPU/memory usage (>90%)
- Disk space critical (<10% free)

### 2. Warning Alerts
- Moderate resource usage (>75%)
- SSL certificate expiring in <30 days
- Failed login attempts

## Performance Tuning

### 1. Database Tuning
```bash
# Access PostgreSQL for tuning
docker-compose -f docker-compose.prod.yml exec postgres psql -U $POSTGRES_USER

# Create indexes for frequently queried columns
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_trades_pair ON trades(pair);
```

### 2. System Tuning
```bash
# Increase file descriptor limits
echo "* soft nofile 65536" >> /etc/security/limits.conf
echo "* hard nofile 65536" >> /etc/security/limits.conf

# Optimize Docker daemon
# Edit /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

## Troubleshooting Common Issues

### 1. Services Not Starting
```bash
# Check logs
docker-compose -f docker-compose.prod.yml logs <service-name>

# Check dependencies
docker-compose -f docker-compose.prod.yml ps

# Verify environment variables
cat .env.prod
```

### 2. Database Connection Issues
```bash
# Check database status
docker-compose -f docker-compose.prod.yml exec postgres pg_isready

# Verify credentials
docker-compose -f docker-compose.prod.yml exec postgres psql -U $POSTGRES_USER -c "\conninfo"
```

### 3. High Resource Usage
```bash
# Monitor with docker stats
docker stats

# Check system resources
htop
iotop
```

## Automation Recommendations

### 1. Cron Jobs
Add to crontab (`crontab -e`):
```bash
# Daily health check at 9 AM
0 9 * * * /path/to/rx-dex/scripts/daily-prod.sh status >> /var/log/rx-dex/daily-check.log 2>&1

# Weekly backup every Sunday at 2 AM
0 2 * * 0 /path/to/rx-dex/scripts/daily-prod.sh backup >> /var/log/rx-dex/weekly-backup.log 2>&1

# Monthly security update first day of month at 3 AM
0 3 1 * * sudo apt update && sudo apt upgrade -y >> /var/log/rx-dex/monthly-update.log 2>&1
```

### 2. Log Rotation
Configure log rotation in `/etc/logrotate.d/rx-dex`:
```bash
/path/to/rx-dex/logs/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 root root
}
```

This guide provides a comprehensive framework for daily operations of the RX-DEX platform in production.