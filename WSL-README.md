# RX-DEX WSL Setup Guide

## Overview

This guide explains how to set up and run the RX-DEX platform in Windows Subsystem for Linux (WSL) with Kali Linux.

## Prerequisites

1. Windows 10/11 with WSL2 enabled
2. Docker Desktop for Windows installed and running
3. WSL with Kali Linux distribution installed

## Installation

### 1. Initial Setup

Run the setup script to install all required dependencies:

```bash
./scripts/setup-rxdex-wsl.sh
```

This script will:
- Install required system packages
- Install Rust and cargo tools
- Configure Docker CLI to connect to Docker Desktop
- Make all scripts executable

### 2. Restart Your Shell

After running the setup script, restart your shell or run:

```bash
source ~/.bashrc
```

## Running RX-DEX

You have two options for running RX-DEX in WSL:

### Option 1: Direct Cargo Execution (Recommended for Development)

This approach runs services directly with cargo for faster development cycles:

```bash
./scripts/daily-dev-wsl.sh
```

This will start all backend services in the background. To stop them:

```bash
./scripts/stop-daily-dev-wsl.sh
```

To check service status:

```bash
./scripts/daily-health-check-wsl.sh
```

In another terminal, start the web frontend:

```bash
cd clients/web
trunk serve --port 8082
```

### Option 2: Docker Compose (Recommended for Testing)

This approach uses Docker containers for a more production-like environment:

```bash
docker-compose -f docker-compose.wsl.yml up --build
```

To stop:

```bash
docker-compose -f docker-compose.wsl.yml down
```

## Service Ports

| Service | Port | Access URL |
|---------|------|------------|
| API Gateway | 8080 | http://localhost:8080 |
| Quoter | 8081 | http://localhost:8081 |
| Web Frontend | 8082 | http://localhost:8082 |
| Order Service | 8083 | http://localhost:8083 |
| User Service | 8084 | http://localhost:8084 |
| Matching Engine | 8085 | http://localhost:8085 |
| Wallet Service | 8086 | http://localhost:8086 |
| Notification Service | 8087 | http://localhost:8087 |
| Admin Service | 8088 | http://localhost:8088 |
| Trading Service | 8089 | http://localhost:8089 |
| Indexer Service | 8090 | http://localhost:8090 |

## Troubleshooting

### Docker Connection Issues

If you encounter Docker connection issues:

1. Ensure Docker Desktop is running on Windows
2. Check that Docker Desktop is configured to expose the daemon on tcp://localhost:2375
3. Verify network connectivity between WSL and Docker Desktop

### Service Not Responding

If services aren't responding:

1. Check logs in `/tmp/` directory (for direct cargo execution)
2. Use `docker-compose logs` (for Docker Compose)
3. Verify all dependencies are running (Redis, PostgreSQL)

### Rust/Cargo Issues

If you encounter Rust or Cargo issues:

1. Ensure Rust is properly installed: `rustc --version`
2. Verify cargo tools are installed: `cargo --version`, `trunk --version`
3. Check that the wasm32 target is installed: `rustup target list --installed`

## Development Workflow

1. Start services using either method above
2. Make code changes
3. For backend services running with cargo, changes will be automatically reloaded
4. For frontend changes, trunk will automatically rebuild and reload
5. Test your changes
6. Stop services when done

## Testing

Run the WSL setup verification script:

```bash
./scripts/test-wsl-setup.sh
```

This will check that all required tools and configurations are properly set up.
