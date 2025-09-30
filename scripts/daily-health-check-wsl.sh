#!/bin/bash

# Daily Health Check for RX-DEX in WSL
echo "Performing RX-DEX Daily Health Check in WSL..."

# Check if services are responding
echo "Checking API Gateway..."
if curl -s -f -m 5 http://localhost:8080/health > /dev/null; then
    echo "✅ API Gateway: OK"
else
    echo "❌ API Gateway: Not responding"
fi

echo "Checking Quoter Service..."
if curl -s -f -m 5 http://localhost:8081/quote/simple > /dev/null; then
    echo "✅ Quoter Service: OK"
else
    echo "❌ Quoter Service: Not responding"
fi

echo "Checking Web Frontend..."
if curl -s -f -m 5 http://localhost:8082 > /dev/null; then
    echo "✅ Web Frontend: OK"
else
    echo "❌ Web Frontend: Not responding"
fi

echo "Health check completed."