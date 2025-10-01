#!/bin/bash

# RX-DEX Development Stopper for WSL
# This script stops the RX-DEX platform services

echo "========================================"
echo "  RX-DEX Development Stopper for WSL"
echo "========================================"
echo ""

# Function to stop services
stop_services() {
    # Check if PID file exists
    if [[ ! -f "/tmp/rxdex-pids" ]]; then
        echo "No RX-DEX processes found to stop."
        exit 0
    fi
    
    # Read PIDs from file and kill processes
    echo "Stopping RX-DEX services..."
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
    rm -rf /tmp/rxdex-logs
    
    echo ""
    echo "✅ All RX-DEX services stopped!"
}

# Function to show help
show_help() {
    echo "RX-DEX Development Stopper for WSL"
    echo ""
    echo "Usage: ./scripts/stop-rxdex-wsl-dev.sh [command]"
    echo ""
    echo "Commands:"
    echo "  stop   - Stop all services (default)"
    echo "  help   - Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./scripts/stop-rxdex-wsl-dev.sh"
    echo "  ./scripts/stop-rxdex-wsl-dev.sh stop"
}

# Main script logic
main() {
    case "$1" in
        stop|"")
            stop_services
            ;;
        help)
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