#!/bin/bash

# RX-DEX Test Script
# This script tests the complete DEX platform

echo "Testing RX-DEX Platform..."

# Check if docker is installed
if ! command -v docker &> /dev/null
then
    echo "Docker is not installed. Please install Docker first."
    exit 1
fi

# Navigate to the rx-dex directory
cd "$(dirname "$0")/../"

# Start services in detached mode
echo "Starting services..."
docker-compose up -d

# Wait for services to start
echo "Waiting for services to start..."
sleep 30

# Test API Gateway
echo "Testing API Gateway..."
curl -f http://localhost:8080/health || echo "API Gateway is not responding"

# Test Trading Service Endpoints
echo "Testing Trading Service..."
curl -f http://localhost:8080/api/market/overview || echo "Market overview endpoint is not responding"
curl -f http://localhost:8080/api/market/orderbook || echo "Order book endpoint is not responding"

# Test Quoter Service
echo "Testing Quoter Service..."
curl -f http://localhost:8080/api/quote/simple || echo "Quoter service is not responding"

# Test Web Frontend
echo "Testing Web Frontend..."
curl -f http://localhost:8082/ || echo "Web frontend is not responding"

echo "Test completed. Check the output above for any errors."
echo "You can access the DEX at: http://localhost:8082"