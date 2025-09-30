#!/bin/bash

# Daily Development Workflow for RX-DEX in WSL
echo "Starting RX-DEX Daily Development Workflow in WSL..."

# Source cargo environment if not already loaded
if ! command -v cargo &> /dev/null; then
    echo "Loading Rust environment..."
    source "$HOME/.cargo/env"
fi

# Check if we're in the correct directory
if [[ ! -f "Cargo.toml" ]]; then
    echo "Error: Please run this script from the rx-dex directory"
    exit 1
fi

# Start services in background processes
echo "Starting QUOTER service..."
cargo run -p quoter > /tmp/quoter.log 2>&1 &
QUOTER_PID=$!

echo "Starting API GATEWAY service..."
cargo run -p api-gateway > /tmp/api-gateway.log 2>&1 &
API_GATEWAY_PID=$!

echo "Starting ORDER SERVICE..."
cargo run -p order-service > /tmp/order-service.log 2>&1 &
ORDER_SERVICE_PID=$!

echo "Starting USER SERVICE..."
cargo run -p user-service > /tmp/user-service.log 2>&1 &
USER_SERVICE_PID=$!

echo "Starting MATCHING ENGINE..."
cargo run -p matching-engine > /tmp/matching-engine.log 2>&1 &
MATCHING_ENGINE_PID=$!

echo "Starting WALLET SERVICE..."
cargo run -p wallet-service > /tmp/wallet-service.log 2>&1 &
WALLET_SERVICE_PID=$!

echo "Starting NOTIFICATION SERVICE..."
cargo run -p notification-service > /tmp/notification-service.log 2>&1 &
NOTIFICATION_SERVICE_PID=$!

# Save PIDs to file for stopping later
echo "$QUOTER_PID" > /tmp/rxdex-pids
echo "$API_GATEWAY_PID" >> /tmp/rxdex-pids
echo "$ORDER_SERVICE_PID" >> /tmp/rxdex-pids
echo "$USER_SERVICE_PID" >> /tmp/rxdex-pids
echo "$MATCHING_ENGINE_PID" >> /tmp/rxdex-pids
echo "$WALLET_SERVICE_PID" >> /tmp/rxdex-pids
echo "$NOTIFICATION_SERVICE_PID" >> /tmp/rxdex-pids

echo "All services started in background processes!"
echo "PIDs saved to /tmp/rxdex-pids"
echo ""
echo "To view service logs:"
echo "  tail -f /tmp/quoter.log"
echo "  tail -f /tmp/api-gateway.log"
echo "  tail -f /tmp/order-service.log"
echo "  tail -f /tmp/user-service.log"
echo "  tail -f /tmp/matching-engine.log"
echo "  tail -f /tmp/wallet-service.log"
echo "  tail -f /tmp/notification-service.log"
echo ""
echo "To start the web frontend, run in a separate terminal:"
echo "  cd clients/web"
echo "  trunk serve --port 8082"
echo ""
echo "To stop all services, run:"
echo "  ./scripts/stop-daily-dev-wsl.sh"