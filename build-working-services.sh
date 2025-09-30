#!/bin/bash

# Script to build only the services that work with our current Docker setup
# These are the services that don't have dependency issues with edition 2024

echo "Building working services..."

# Build services that work
docker-compose build quoter
docker-compose build api-gateway
docker-compose build user-service
docker-compose build wallet-service
docker-compose build notification-service
docker-compose build admin-service
docker-compose build indexer

echo "Build process completed for working services."
echo "The following services have dependency issues and were not built:"
echo "- order-service"
echo "- matching-engine"
echo "- trading-service"
echo "- web"