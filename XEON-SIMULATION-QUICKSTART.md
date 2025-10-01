# Xeon Server Simulation Quick Start Guide

## Overview

This guide provides quick instructions for setting up and running the RX-DEX platform in a WSL environment to simulate your Xeon server deployment.

## Prerequisites

1. Windows 10/11 with WSL2 installed
2. Ubuntu distribution installed in WSL
3. At least 16GB RAM and 4 CPU cores allocated to WSL
4. Docker Desktop for Windows installed

## Quick Setup

### 1. Access Your Ubuntu WSL Environment

Open PowerShell and enter your Ubuntu WSL environment:

```powershell
wsl -d Ubuntu
```

### 2. Navigate to the Project Directory

```bash
cd /mnt/c/Users/RMT/Documents/vscodium/crypto-Exchange-Rust-Base/RX-DEX/rx-dex
```

### 3. Run the Xeon Simulation Setup

```bash
./scripts/setup-xeon-wsl.sh
```

This will:
- Update your system packages
- Install Docker and Docker Compose
- Install Nginx and Certbot
- Configure the firewall
- Create a production environment file (.env.prod)
- Build all Docker images

### 4. Start Services

```bash
./scripts/daily-prod.sh start
```

### 5. Check Service Status

```bash
./scripts/daily-prod.sh status
```

You should see all services in the "Up" state.

## Accessing the Simulation

Once running, you can access your RX-DEX simulation at:
- Web Interface: http://localhost:8082
- API Gateway: http://localhost:8080

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

### Viewing Logs

```bash
./scripts/daily-prod.sh logs
```

### Updating Services

```bash
./scripts/daily-prod.sh update
```

## Windows PowerShell Alternative

If you prefer to use PowerShell, you can run the PowerShell version of the setup script:

```powershell
.\scripts\setup-xeon-wsl.ps1
```

And then start services with:

```powershell
wsl -d Ubuntu -e /mnt/c/Users/RMT/Documents/vscodium/crypto-Exchange-Rust-Base/RX-DEX/rx-dex/scripts/daily-prod.sh start
```

## Troubleshooting

### Common Issues

1. **Docker Permission Denied**:
   - Log out and log back into your WSL session
   - Ensure your user is in the docker group: `sudo usermod -aG docker $USER`

2. **Services Not Starting**:
   - Check logs: `./scripts/daily-prod.sh logs`
   - Verify dependencies are running: `./scripts/daily-prod.sh status`

3. **Port Conflicts**:
   - Ensure no other services are using ports 8080-8090
   - Check with: `netstat -tulpn | grep :808`

### Resource Allocation

Ensure your WSL environment has sufficient resources:
1. Open PowerShell as Administrator
2. Edit .wslconfig:
   ```powershell
   notepad "$env:USERPROFILE/.wslconfig"
   ```
3. Add the following configuration:
   ```
   [wsl2]
   memory=16GB
   processors=4
   ```

## Next Steps

After successfully running the simulation:
1. Review the [PRODUCTION-DEPLOYMENT-GUIDE.md](PRODUCTION-DEPLOYMENT-GUIDE.md) for deploying to your actual Xeon server
2. Configure your domain with GoDaddy using the [DOMAIN-CONFIGURATION-GUIDE.md](DOMAIN-CONFIGURATION-GUIDE.md)
3. Test all functionality in the simulation before deploying to production