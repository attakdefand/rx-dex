# Domain Configuration Guide for toklo.xyz

## Overview

This guide will help you configure your toklo.xyz domain registered with GoDaddy to work with your RX-DEX deployment on your Xeon server.

## Prerequisites

1. Your toklo.xyz domain registered with GoDaddy
2. Your Xeon server with a static IP address
3. Access to your GoDaddy account

## Step-by-Step Configuration

### 1. Obtain Your Server's IP Address

First, you need to know your server's public IP address. You can find it by running this command on your server:

```bash
curl ifconfig.me
```

Make note of this IP address as you'll need it for the DNS configuration.

### 2. Configure DNS Settings in GoDaddy

1. Log in to your GoDaddy account at https://account.godaddy.com/
2. Navigate to "Domains" and select "Manage" next to toklo.xyz
3. Click on "DNS" in the management panel
4. Add the following DNS records:

#### A Records:
- **Host**: @ (or leave blank)
  **Points to**: [Your Server's IP Address]
  **TTL**: 1 hour

- **Host**: www
  **Points to**: [Your Server's IP Address]
  **TTL**: 1 hour

#### CNAME Records (if needed):
- **Host**: ftp
  **Points to**: @
  **TTL**: 1 hour

### 3. Configure Nginx on Your Server

Once your DNS is configured, you'll need to set up Nginx on your server. Add the following configuration to `/etc/nginx/sites-available/rx-dex`:

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

Then enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/rx-dex /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 4. Obtain SSL Certificate

After DNS propagation (which can take up to 48 hours but is usually much faster), obtain an SSL certificate using Certbot:

```bash
sudo certbot --nginx -d toklo.xyz -d www.toklo.xyz
```

## Verification

To verify your configuration:

1. Check DNS propagation:
   ```bash
   nslookup toklo.xyz
   nslookup www.toklo.xyz
   ```

2. Visit your website in a browser:
   - http://toklo.xyz
   - http://www.toklo.xyz
   - https://toklo.xyz (after SSL setup)

## Troubleshooting

### DNS Issues

- DNS changes can take up to 48 hours to propagate globally, but usually happen much faster
- You can check propagation at https://dnschecker.org/
- If you're having issues, try flushing your local DNS cache

### SSL Certificate Issues

- Make sure your DNS records are properly configured before running Certbot
- Check that port 80 is accessible on your server
- Verify your firewall settings allow HTTP/HTTPS traffic

## Additional Resources

- [GoDaddy DNS Management Help](https://www.godaddy.com/help/manage-dns-records-32598)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [Nginx Documentation](https://nginx.org/en/docs/)