#!/bin/bash

# Stop Daily Development Workflow for RX-DEX in WSL
echo "Stopping RX-DEX Daily Development Workflow in WSL..."

# Check if PID file exists
if [[ ! -f "/tmp/rxdex-pids" ]]; then
    echo "No RX-DEX processes found to stop."
    exit 0
fi

# Read PIDs from file and kill processes
while read pid; do
    if kill -0 $pid 2>/dev/null; then
        echo "Stopping process $pid..."
        kill $pid
    else
        echo "Process $pid not running."
    fi
done < /tmp/rxdex-pids

# Remove PID file
rm /tmp/rxdex-pids

# Clean up log files
echo "Cleaning up log files..."
rm -f /tmp/quoter.log
rm -f /tmp/api-gateway.log
rm -f /tmp/order-service.log
rm -f /tmp/user-service.log
rm -f /tmp/matching-engine.log
rm -f /tmp/wallet-service.log
rm -f /tmp/notification-service.log

echo "All RX-DEX services stopped!"