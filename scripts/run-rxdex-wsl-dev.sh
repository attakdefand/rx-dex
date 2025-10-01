#!/bin/bash

# RX-DEX Development Runner for WSL
# This script starts the RX-DEX platform using Cargo for development

echo "========================================"
echo "  RX-DEX Development Runner for WSL"
echo "========================================"
echo ""

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

# Function to start services
start_services() {
    echo "Starting RX-DEX services..."
    
    # Create log directory if it doesn't exist
    mkdir -p /tmp/rxdex-logs
    
    # Start services in background processes
    echo "Starting QUOTER service..."
    cargo run -p quoter > /tmp/rxdex-logs/quoter.log 2>&1 &
    QUOTER_PID=$!
    
    echo "Starting API GATEWAY service..."
    cargo run -p api-gateway > /tmp/rxdex-logs/api-gateway.log 2>&1 &
    API_GATEWAY_PID=$!
    
    echo "Starting ORDER SERVICE..."
    cargo run -p order-service > /tmp/rxdex-logs/order-service.log 2>&1 &
    ORDER_SERVICE_PID=$!
    
    echo "Starting USER SERVICE..."
    cargo run -p user-service > /tmp/rxdex-logs/user-service.log 2>&1 &
    USER_SERVICE_PID=$!
    
    echo "Starting MATCHING ENGINE..."
    cargo run -p matching-engine > /tmp/rxdex-logs/matching-engine.log 2>&1 &
    MATCHING_ENGINE_PID=$!
    
    echo "Starting WALLET SERVICE..."
    cargo run -p wallet-service > /tmp/rxdex-logs/wallet-service.log 2>&1 &
    WALLET_SERVICE_PID=$!
    
    echo "Starting NOTIFICATION SERVICE..."
    cargo run -p notification-service > /tmp/rxdex-logs/notification-service.log 2>&1 &
    NOTIFICATION_SERVICE_PID=$!
    
    # Save PIDs to file for stopping later
    echo "$QUOTER_PID" > /tmp/rxdex-pids
    echo "$API_GATEWAY_PID" >> /tmp/rxdex-pids
    echo "$ORDER_SERVICE_PID" >> /tmp/rxdex-pids
    echo "$USER_SERVICE_PID" >> /tmp/rxdex-pids
    echo "$MATCHING_ENGINE_PID" >> /tmp/rxdex-pids
    echo "$WALLET_SERVICE_PID" >> /tmp/rxdex-pids
    echo "$NOTIFICATION_SERVICE_PID" >> /tmp/rxdex-pids
    
    echo ""
    echo "✅ All services started in background processes!"
    echo "PIDs saved to /tmp/rxdex-pids"
    echo ""
    echo "To view service logs:"
    echo "  tail -f /tmp/rxdex-logs/*.log"
    echo ""
    echo "To start the web frontend, run in a separate terminal:"
    echo "  cd clients/web"
    echo "  trunk serve --port 8082"
    echo ""
    echo "To stop all services, run:"
    echo "  ./scripts/stop-rxdex-wsl-dev.sh"
}

# Function to check service status
check_status() {
    if [[ ! -f "/tmp/rxdex-pids" ]]; then
        echo "No RX-DEX processes found."
        return
    fi
    
    echo "RX-DEX Service Status:"
    echo "====================="
    
    while read pid; do
        if kill -0 $pid 2>/dev/null; then
            echo "Process $pid: RUNNING"
        else
            echo "Process $pid: STOPPED"
        fi
    done < /tmp/rxdex-pids
}

# Function to show logs
show_logs() {
    if [[ ! -d "/tmp/rxdex-logs" ]]; then
        echo "No logs found."
        return
    fi
    
    echo "Showing last 10 lines of each log file:"
    echo "======================================"
    
    for logfile in /tmp/rxdex-logs/*.log; do
        if [[ -f "$logfile" ]]; then
            echo ""
            echo "$(basename $logfile):"
            tail -n 10 "$logfile"
        fi
    done
}

# Function to show help
show_help() {
    echo "RX-DEX Development Runner for WSL"
    echo ""
    echo "Usage: ./scripts/run-rxdex-wsl-dev.sh [command]"
    echo ""
    echo "Commands:"
    echo "  start   - Start all services"
    echo "  status  - Check service status"
    echo "  logs    - Show service logs"
    echo "  help    - Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./scripts/run-rxdex-wsl-dev.sh start"
    echo "  ./scripts/run-rxdex-wsl-dev.sh status"
}

# Main script logic
main() {
    case "$1" in
        start)
            start_services
            ;;
        status)
            check_status
            ;;
        logs)
            show_logs
            ;;
        help|"")
            show_help
            ;;
        *)
            echo "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"