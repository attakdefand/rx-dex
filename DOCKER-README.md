# RX-DEX Docker Setup

This document explains how to run the RX-DEX crypto exchange using Docker.

## Prerequisites

- Docker Desktop for Windows
- PowerShell (for running scripts)

## Quick Start

1. **Start all services**:
   ```powershell
   .\scripts\start-rxdex.ps1
   ```

2. **Access the web interface**:
   Open your browser and go to http://localhost:8082

3. **Stop all services**:
   ```powershell
   .\scripts\stop-rxdex.ps1
   ```

## Services Overview

| Service | Port | Description |
|---------|------|-------------|
| Web Frontend | 8082 | Yew-based web interface |
| API Gateway | 8080 | Main entry point for API requests |
| Quoter Service | 8081 | Price quoting service |
| Order Service | 8083 | Order management service |
| User Service | 8084 | User authentication and management |
| Matching Engine | 8085 | Order matching engine |
| Wallet Service | 8086 | Wallet and balance management |
| Notification Service | 8087 | Email/SMS notifications |
| Redis | 6379 | In-memory data store |
| PostgreSQL | 5432 | Relational database |

## Manual Commands

### Start Services
```bash
# Development setup (fast startup with placeholder services)
docker-compose -f docker-compose.dev.yml up -d

# Full build (compiles all services from source - slow but complete)
docker-compose up -d
```

### Stop Services
```bash
# Stop development services
docker-compose -f docker-compose.dev.yml down

# Stop full build services
docker-compose down
```

### View Logs
```bash
# View all logs
docker-compose -f docker-compose.dev.yml logs -f

# View specific service logs
docker-compose -f docker-compose.dev.yml logs -f api-gateway
```

### List Running Services
```bash
docker-compose -f docker-compose.dev.yml ps
```

## Development vs Production

### Development Setup (`docker-compose.dev.yml`)
- Uses pre-built images or placeholders for faster startup
- Ideal for testing the overall architecture
- Services return placeholder responses

### Production Setup (`docker-compose.yml`)
- Builds all services from source code
- Full implementation of all services
- Much longer build time but complete functionality

## Troubleshooting

### Services not starting
1. Make sure Docker Desktop is running
2. Check if ports are already in use:
   ```powershell
   netstat -ano | findstr :8080
   ```
3. Stop any conflicting processes or change ports in docker-compose files

### Web interface not loading
1. Verify the web service is running:
   ```powershell
   docker-compose -f docker-compose.dev.yml ps
   ```
2. Check the web service logs:
   ```powershell
   docker-compose -f docker-compose.dev.yml logs web
   ```

### Database connection issues
1. Verify PostgreSQL is running:
   ```powershell
   docker-compose -f docker-compose.dev.yml ps postgres
   ```
2. Check database credentials in the docker-compose file

## Building from Source

To build the full RX-DEX system from source:

1. Ensure you have the Cargo.lock file in the clients/web directory
2. Run the full build:
   ```bash
   docker-compose up -d
   ```

Note: This will take a significant amount of time (10-30 minutes) as it compiles all Rust services.

## Testing and Performance

### Concurrency Testing
Use the provided PowerShell scripts for comprehensive concurrency testing:
```powershell
# Run standard concurrency test
.\scripts\concurrency-test.ps1

# Run with custom parameters
.\scripts\concurrency-test.ps1 -concurrentUsers 2000 -requestsPerUser 50 -durationMinutes 10
```

### Load Testing
For high-performance load testing, install and use wrk:
```powershell
# Install wrk
.\scripts\install-wrk.ps1

# Run load test
wrk -t12 -c400 -d30s http://localhost:8081/quote/simple
```

### Resource Monitoring
Monitor system resources during testing:
```powershell
.\scripts\monitor-resources.ps1 -durationSeconds 300 -intervalSeconds 10
```

## Using Docker with WSL

You can run the RX-DEX Docker setup from within WSL:

1. Copy the project to WSL:
   ```bash
   # From Windows PowerShell in the rx-dex directory
   .\scripts\copy-to-wsl.sh
   ```

2. Access WSL and navigate to the project:
   ```bash
   wsl
   cd ~/rx-dex
   ```

3. Start services using Docker Compose:
   ```bash
   docker-compose -f docker-compose.wsl.yml up -d
   ```

4. Access services at the same ports (http://localhost:8080, http://localhost:8081, etc.)

Note: Docker Desktop must be running on Windows for this to work.

## Customization

### Changing Ports
Edit the `docker-compose.dev.yml` file and modify the port mappings under each service.

### Environment Variables
Environment variables can be added to services in the docker-compose files under the `environment` section.

### Persistent Data
Redis and PostgreSQL data are stored in Docker volumes and will persist between container restarts.