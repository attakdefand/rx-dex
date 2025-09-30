# Admin Service

The Admin Service is a dedicated backend service for managing the RX-DEX platform. It provides endpoints for monitoring system statistics, managing users, and performing administrative tasks.

## Features

- System statistics monitoring
- User management
- Administrative authentication
- RESTful API design

## API Endpoints

### Authentication
- `POST /api/admin/login` - Admin login endpoint

### Statistics
- `GET /api/admin/stats` - Get system statistics

### User Management
- `GET /api/admin/users` - Get list of users

## Running the Service

### With Docker

```bash
docker-compose up admin-service
```

### Locally

```bash
cd services/admin-service
cargo run
```

The service will start on port 8088.

## Environment Variables

- `ADMIN_USERNAME` - Admin username (default: "admin")
- `ADMIN_PASSWORD` - Admin password (default: "admin123")

## Integration with API Gateway

The admin service endpoints are accessible through the API Gateway:

- `GET /api/admin/stats` - Get system statistics
- `GET /api/admin/users` - Get list of users

## Security Considerations

In a production environment, you should:

1. Use strong authentication mechanisms (JWT, OAuth2)
2. Implement role-based access control
3. Use HTTPS for all communications
4. Store passwords securely with proper hashing
5. Implement rate limiting
6. Add input validation and sanitization