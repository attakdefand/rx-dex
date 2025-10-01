# API Documentation

This document provides details about the RX-DEX API endpoints.

## Authentication

All API requests require authentication via JWT tokens. Include the token in the `Authorization` header:

```
Authorization: Bearer <your-jwt-token>
```

## Endpoints

### User Service

#### Register a new user
```
POST /api/users/register
```

Request body:
```json
{
  "username": "string",
  "email": "string",
  "password": "string"
}
```

#### Login
```
POST /api/users/login
```

Request body:
```json
{
  "email": "string",
  "password": "string"
}
```

### Wallet Service

#### Get user wallet balance
```
GET /api/wallet/balance
```

Response:
```json
{
  "balances": {
    "BTC": "0.5",
    "ETH": "10.0",
    "USDT": "1000.0"
  }
}
```

### Order Service

#### Place a new order
```
POST /api/orders
```

Request body:
```json
{
  "pair": "BTC/USDT",
  "side": "buy|sell",
  "price": "number",
  "quantity": "number"
}
```

#### Get user orders
```
GET /api/orders
```

Response:
```json
[
  {
    "id": "string",
    "pair": "BTC/USDT",
    "side": "buy|sell",
    "price": "number",
    "quantity": "number",
    "status": "open|filled|cancelled",
    "created_at": "timestamp"
  }
]
```

### Market Data

#### Get order book
```
GET /api/market/orderbook?pair=BTC/USDT
```

Response:
```json
{
  "bids": [["price", "quantity"], ...],
  "asks": [["price", "quantity"], ...]
}
```

#### Get recent trades
```
GET /api/market/trades?pair=BTC/USDT
```

Response:
```json
[
  {
    "price": "number",
    "quantity": "number",
    "timestamp": "timestamp",
    "side": "buy|sell"
  }
]
```

## Error Responses

All error responses follow this format:

```json
{
  "error": {
    "code": "string",
    "message": "string"
  }
}
```

Common error codes:
- `UNAUTHORIZED`: Missing or invalid authentication token
- `VALIDATION_ERROR`: Request body validation failed
- `NOT_FOUND`: Resource not found
- `INTERNAL_ERROR`: Server error