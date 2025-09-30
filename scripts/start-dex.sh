#!/bin/bash

# RX-DEX Start Script
# This script starts the complete DEX platform

echo "Starting RX-DEX Platform..."

# Check if docker is installed
if ! command -v docker &> /dev/null
then
    echo "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if docker-compose is installed
if ! command -v docker-compose &> /dev/null
then
    echo "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Navigate to the rx-dex directory
cd "$(dirname "$0")/../"

# Build and start all services
echo "Building and starting all services..."
docker-compose up --build -d

# Wait for services to start
echo "Waiting for services to start..."
sleep 30

# Check if services are running
echo "Checking service status..."
docker-compose ps

echo "RX-DEX Platform is now running!"
echo "Access the web interface at: http://localhost:8082"
echo "Access the API at: http://localhost:8080"