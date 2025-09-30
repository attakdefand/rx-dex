# RX-DEX: Complete Decentralized Exchange

## Overview

RX-DEX is a high-performance decentralized exchange built with Rust. This document explains how to run the complete DEX platform with all services working together.

## Architecture

The RX-DEX platform consists of the following microservices:

1. **API Gateway** - Entry point for all client requests
2. **Trading Service** - Core trading functionality (market data, order placement)
3. **Quoter Service** - Price quoting functionality
4. **User Service** - User management
5. **Order Service** - Order management
6. **Matching Engine** - Order matching
7. **Wallet Service** - Asset management
8. **Notification Service** - User notifications
9. **Admin Service** - Administrative functions
10. **Indexer Service** - Blockchain data indexing
11. **Web Frontend** - User interface

## Prerequisites

- Docker and Docker Compose
- Rust toolchain (for development)
- Node.js and npm (for development tools)

## Running the Complete DEX

### Using Docker Compose (Recommended)

1. Navigate to the rx-dex directory:
   ```bash
   cd rx-dex
   ```

2. Build and start all services:
   ```bash
   docker-compose up --build
   ```

3. Access the DEX:
   - Web Interface: http://localhost:8082
   - API Gateway: http://localhost:8080
   - Individual services on their respective ports

### Development Mode

For development, you can use the dev docker-compose file:

```bash
docker-compose -f docker-compose.dev.yml up --build
```

### WSL Mode

If you're using WSL:

```bash
docker-compose -f docker-compose.wsl.yml up --build
```

## Services and Ports

| Service | Port | Description |
|---------|------|-------------|
| API Gateway | 8080 | Entry point for all requests |
| Quoter | 8081 | Price quoting service |
| Web Frontend | 8082 | User interface |
| Order Service | 8083 | Order management |
| User Service | 8084 | User management |
| Matching Engine | 8085 | Order matching |
| Wallet Service | 8086 | Asset management |
| Notification Service | 8087 | User notifications |
| Admin Service | 8088 | Administrative functions |
| Trading Service | 8089 | Core trading functionality |
| Indexer Service | 8090 | Blockchain data indexing |

## Key Features

### Trading Features
- Real-time market data
- Order book visualization
- Limit and market orders
- Order management
- Trade history

### User Features
- Wallet management
- Order history
- Trade history
- Real-time notifications

### Admin Features
- User management
- System monitoring
- Trade analytics

### Indexer Features
- Blockchain data indexing
- Transaction history
- Event processing

## API Endpoints

### Market Data
- `GET /api/market/overview` - Get market overview
- `GET /api/market/orderbook` - Get order book

### Trading
- `POST /api/orders` - Place order
- `POST /api/orders/cancel` - Cancel order
- `GET /api/orders/user` - Get user orders

### Admin
- `GET /api/admin/stats` - Get system statistics
- `GET /api/admin/users` - Get user list

## Development Workflow

### Daily Tasks

1. Start all services:
   ```bash
   docker-compose up -d
   ```

2. Monitor logs:
   ```bash
   docker-compose logs -f
   ```

3. Stop services:
   ```bash
   docker-compose down
   ```

### Testing

1. Unit tests:
   ```bash
   cargo test
   ```

2. Integration tests:
   ```bash
   docker-compose -f docker-compose.dev.yml up -d
   # Run integration tests
   ```

## Scaling for Production

The RX-DEX platform is designed to scale:

1. **Horizontal Scaling**: Each service can be scaled independently
2. **Load Balancing**: Use a load balancer in front of the API Gateway
3. **Database Scaling**: Use database replication and sharding
4. **Caching**: Implement Redis caching for frequently accessed data
5. **CDN**: Use a CDN for static assets

## Security Considerations

1. **Authentication**: JWT-based authentication
2. **Authorization**: Role-based access control
3. **Rate Limiting**: Built-in rate limiting in API Gateway
4. **Data Encryption**: TLS for data in transit, encryption for data at rest
5. **Input Validation**: Strict input validation on all endpoints

## Monitoring and Logging

1. **Logging**: Structured logging in JSON format
2. **Metrics**: Prometheus metrics endpoint
3. **Tracing**: OpenTelemetry tracing
4. **Health Checks**: Health check endpoints for all services

## Troubleshooting

### Common Issues

1. **Port Conflicts**: Ensure no other services are using the required ports
2. **Docker Issues**: Restart Docker daemon if services fail to start
3. **Database Issues**: Check database connection strings and credentials

### Logs

Check service logs:
```bash
docker-compose logs <service-name>
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Write tests
5. Submit a pull request

## License

This project is licensed under the MIT License.