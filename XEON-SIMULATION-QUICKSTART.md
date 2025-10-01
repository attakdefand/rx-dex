# Xeon Server Simulation Quick Start Guide

## Overview

This guide provides quick instructions for setting up and running the RX-DEX platform in a WSL environment to simulate your Xeon server deployment.

## Prerequisites

1. Windows 10/11 with WSL2 installed
2. Ubuntu distribution installed in WSL
3. At least 16GB RAM and 4 CPU cores allocated to WSL
4. Docker Desktop for Windows installed
5. Rust toolchain installed in WSL

## Quick Setup

### 1. Install Docker Desktop for Windows

If you haven't already, download and install Docker Desktop for Windows from [Docker's official website](https://www.docker.com/products/docker-desktop).

### 2. Enable WSL 2 Integration in Docker Desktop

1. Open Docker Desktop
2. Go to Settings > Resources > WSL Integration
3. Enable integration with your Ubuntu distribution
4. Click "Apply & Restart"

### 3. Access Your Ubuntu WSL Environment

Open PowerShell and enter your Ubuntu WSL environment:

```powershell
wsl -d Ubuntu
```

### 4. Navigate to the Project Directory

```bash
cd /mnt/c/Users/RMT/Documents/vscodium/crypto-Exchange-Rust-Base/RX-DEX/rx-dex
```

### 5. Run the Xeon Simulation Setup

```bash
./scripts/setup-xeon-wsl.sh
```

This will:
- Update your system packages
- Install required packages
- Configure Docker Desktop integration
- Create a production environment file (.env.prod)
- Make scripts executable
- Build Docker images (if Docker is properly configured)

### 6. Start Services

For the Xeon simulation, you have two options:

#### Option A: Run services directly with Cargo (Recommended for development)

```bash
./scripts/daily-dev-wsl.sh
```

Then in another terminal, start the web frontend:
```bash
cd clients/web
trunk serve --port 8082
```

#### Option B: Run services with Docker (If Docker is properly configured)

```bash
docker-compose -f docker-compose.wsl.yml up
```

### 7. Check Service Status

For the Cargo-based approach:
```bash
./scripts/daily-health-check-wsl.sh
```

For the Docker-based approach:
```bash
docker-compose -f docker-compose.wsl.yml ps
```

## Accessing the Simulation

Once running, you can access your RX-DEX simulation at:
- Web Interface: http://localhost:8082
- API Gateway: http://localhost:8080

## Daily Operations

### Starting Services (Cargo-based)

```bash
./scripts/daily-dev-wsl.sh
```

### Stopping Services (Cargo-based)

```bash
./scripts/stop-daily-dev-wsl.sh
```

### Starting Services (Docker-based)

```bash
docker-compose -f docker-compose.wsl.yml up -d
```

### Stopping Services (Docker-based)

```bash
docker-compose -f docker-compose.wsl.yml down
```

### Viewing Logs (Cargo-based)

```bash
tail -f /tmp/*.log
```

### Viewing Logs (Docker-based)

```bash
docker-compose -f docker-compose.wsl.yml logs -f
```

## Windows PowerShell Alternative

If you prefer to use PowerShell, you can run the PowerShell version of the setup script:

```powershell
.\scripts\setup-xeon-wsl.ps1
```

And then start services with either approach:

#### Cargo-based (recommended):
```powershell
wsl -d Ubuntu -e /mnt/c/Users/RMT/Documents/vscodium/crypto-Exchange-Rust-Base/RX-DEX/rx-dex/scripts/daily-dev-wsl.sh
```

#### Docker-based:
```powershell
wsl -d Ubuntu -e docker-compose -f /mnt/c/Users/RMT/Documents/vscodium/crypto-Exchange-Rust-Base/RX-DEX/rx-dex/docker-compose.wsl.yml up
```

## Troubleshooting

### Common Issues

1. **Docker Permission Denied**:
   - Ensure Docker Desktop is running
   - Verify WSL integration is enabled in Docker Desktop settings
   - Check that you can run `docker version` in WSL

2. **Services Not Starting**:
   - Check logs for specific service errors
   - For Cargo-based: `tail -f /tmp/*.log`
   - For Docker-based: `docker-compose -f docker-compose.wsl.yml logs`

3. **Port Conflicts**:
   - Ensure no other services are using ports 8080-8090
   - Check with: `netstat -tulpn | grep :808`

4. **Rust/Cargo Not Found**:
   - Install Rust in WSL: `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`
   - Reload shell: `source ~/.cargo/env`

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