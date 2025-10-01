# RX-DEX - Distributed Crypto Exchange

A high-performance, distributed cryptocurrency exchange built with Rust microservices.

## Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Load Balancer │────│   API Gateway    │────│  Rate Limiter   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌──────────────┐      ┌──────────────┐     ┌──────────────┐
│  Quote       │      │  Order       │     │  User        │
│  Service     │      │  Service     │     │  Service     │
└──────────────┘      └──────────────┘     └──────────────┘
        │                     │                     │
        └─────────────────────┼─────────────────────┘
                              ▼
                    ┌──────────────────┐
                    │   Event Bus      │
                    │  (Redis/Kafka)   │
                    └──────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌──────────────┐      ┌──────────────┐     ┌──────────────┐
│  Matching    │      │  Risk        │     │  Settlement  │
│  Engine      │      │  Management  │     │  Service     │
└──────────────┘      └──────────────┘     └──────────────┘
```

## Services

1. **API Gateway** (`services/api-gateway`) - Port 8080
   - Entry point for all client requests
   - Authentication and rate limiting
   - Routes requests to appropriate services

2. **Quoter Service** (`services/quoter`) - Port 8081
   - Provides price quotes for trading pairs
   - Calculates slippage and fees

3. **Order Service** (`services/order-service`) - Port 8083
   - Manages order creation and cancellation
   - Publishes order events to message queue

4. **User Service** (`services/user-service`) - Port 8084
   - User registration and authentication
   - KYC verification
   - User profile management

5. **Matching Engine** (`services/matching-engine`) - Port 8085
   - High-performance order matching
   - Maintains order books
   - Generates trade executions

6. **Wallet Service** (`services/wallet-service`) - Port 8086
   - Manages user cryptocurrency wallets
   - Processes deposits and withdrawals
   - Handles internal transfers

7. **Notification Service** (`services/notification-service`) - Port 8087
   - Sends email, SMS, and push notifications
   - Handles user alerts and updates

8. **Web Frontend** (`clients/web`) - Port 8082
   - Yew-based web interface
   - Responsive trading dashboard

## Libraries

1. **dex-math** (`libs/dex-math`) - Mathematical functions for DEX operations
2. **dex-primitives** (`libs/dex-primitives`) - Basic data structures
3. **dex-oracle** (`libs/dex-oracle`) - Price oracle integration
4. **dex-sdk-rs** (`libs/dex-sdk-rs`) - SDK for interacting with the DEX
5. **dex-messaging** (`libs/dex-messaging`) - Event-driven communication between services

## Contracts

1. **cw-amm-cpmm** - Constant Product AMM implementation
2. **cw-factory** - Contract factory
3. **cw-router** - Routing contract
4. **cw-fee-treasury** - Fee management
5. **cw-lp-token** - Liquidity provider tokens
6. **cw-stake** - Staking contract
7. **cw-gov** - Governance contract

## Getting Started

### Prerequisites

- Rust 1.75+
- Docker and Docker Compose
- Kubernetes (for production deployment)
- Node.js (for load testing)

### Development Setup

1. Install dependencies:
   ```bash
   rustup target add wasm32-unknown-unknown
   cargo install cargo-watch trunk
   ```

2. Start all services:
   ```bash
   # In PowerShell
   .\scripts\dev.ps1
   ```

3. Start the web frontend:
   ```bash
   cd clients/web
   trunk serve --port 8082
   ```

### Running the Complete DEX

For a fully functional DEX experience, use the complete setup:

1. **Using Docker Compose (Recommended)**:
   ```bash
   docker-compose up --build
   ```

2. **Using the Start Scripts**:
   - On Windows: Run `scripts/start-dex.bat` or `scripts/start-dex.ps1`
   - On Linux/Mac: Run `scripts/start-dex.sh`

3. **Access the DEX**:
   - Web Interface: http://localhost:8082
   - API Gateway: http://localhost:8080

For detailed instructions on running the complete DEX, see [COMPLETE-DEX-README.md](COMPLETE-DEX-README.md)

### Production Deployment

For production deployment on your Xeon server with the domain name toklo.xyz:

1. Follow the comprehensive [PRODUCTION-DEPLOYMENT-GUIDE.md](PRODUCTION-DEPLOYMENT-GUIDE.md) for step-by-step deployment instructions
2. Configure your domain with GoDaddy using the [DOMAIN-CONFIGURATION-GUIDE.md](DOMAIN-CONFIGURATION-GUIDE.md)
3. Use the [DAILY-OPERATIONS-GUIDE.md](DAILY-OPERATIONS-GUIDE.md) for ongoing maintenance
4. Run the setup script: `sudo ./scripts/setup-prod.sh` (Linux) or `.\scripts\setup-prod.ps1` (Windows)

### WSL Setup (Kali Linux)

For users who prefer to develop in WSL with Kali Linux:

1. Copy project to WSL:
   ```powershell
   .\scripts\copy-to-wsl.sh
   ```

2. Access WSL and run setup:
   ```bash
   wsl
   cd ~/rx-dex
   chmod +x scripts/setup-rxdex-wsl.sh
   ./scripts/setup-rxdex-wsl.sh
   ```

3. For detailed WSL setup instructions, see [WSL-README.md](WSL-README.md)

For detailed Docker setup instructions, see [DOCKER-README.md](DOCKER-README.md)

## Docker Build Fixes

Recent updates have resolved Docker build issues that were preventing services from building correctly. See [DOCKER-FIXES-SUMMARY.md](DOCKER-FIXES-SUMMARY.md) for details on the fixes applied.

## WSL Fixes

The WSL setup has been improved to work correctly with Docker Desktop and provide two options for development:
1. Direct cargo execution for fast development cycles
2. Docker Compose for a production-like environment

See [WSL-README.md](WSL-README.md) for detailed instructions.

## Scaling to 300M Users

The architecture is designed to scale horizontally:

1. **Horizontal Pod Autoscaling** - Services automatically scale based on CPU/memory usage
2. **Database Sharding** - User data partitioned across multiple database instances
3. **Redis Clustering** - Distributed caching for high availability
4. **Message Queue Clustering** - Kafka/Pulsar clusters for event processing
5. **CDN Integration** - Content delivery network for static assets
6. **Geographic Distribution** - Multi-region deployment for low latency

## Performance Targets

- **Order Processing**: 1M orders/second
- **Matching Engine**: 500K matches/second
- **API Latency**: < 50ms p99
- **Uptime**: 99.99%
- **Database**: PostgreSQL with read replicas

## Monitoring and Observability

- **Prometheus** - Metrics collection
- **Grafana** - Dashboard and visualization
- **ELK Stack** - Log aggregation and analysis
- **Jaeger** - Distributed tracing
- **Alertmanager** - Incident response

## Security Features

- **Rate Limiting** - Prevent abuse and DDoS attacks
- **Authentication** - JWT-based user authentication
- **Authorization** - Role-based access control
- **Encryption** - TLS for all communications
- **Audit Logs** - Comprehensive activity logging
- **Compliance** - KYC/AML integration

## Testing

1. Unit tests:
   ```bash
   cargo test
   ```

2. Integration tests:
   ```bash
   cargo test --features integration
   ```

3. Load testing:
   ```bash
   node scripts/load-test.js
   ```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a pull request

## License

Apache 2.0