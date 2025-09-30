#!/bin/bash

# Daily Production Operations for RX-DEX
# This script provides common daily operations for the RX-DEX production environment

echo "========================================"
echo "  RX-DEX Daily Production Operations"
echo "========================================"
echo ""

# Function to check if script is run as root or with sudo
check_privileges() {
    if [[ $EUID -eq 0 ]]; then
        echo "This script should not be run as root. Please run as a regular user with sudo privileges."
        exit 1
    fi
}

# Function to check if required files exist
check_requirements() {
    if [[ ! -f ".env.prod" ]]; then
        echo "❌ Error: .env.prod file not found!"
        echo "   Please create .env.prod file with production environment variables."
        exit 1
    fi
    
    if [[ ! -f "docker-compose.prod.yml" ]]; then
        echo "❌ Error: docker-compose.prod.yml file not found!"
        echo "   Please create docker-compose.prod.yml file."
        exit 1
    fi
}

# Function to load environment variables
load_env() {
    export $(cat .env.prod | xargs)
    echo "✅ Environment variables loaded"
}

# Function to start services
start_services() {
    echo "Starting RX-DEX services..."
    docker-compose -f docker-compose.prod.yml up -d
    if [[ $? -eq 0 ]]; then
        echo "✅ Services started successfully"
    else
        echo "❌ Failed to start services"
        exit 1
    fi
}

# Function to stop services
stop_services() {
    echo "Stopping RX-DEX services..."
    docker-compose -f docker-compose.prod.yml down
    if [[ $? -eq 0 ]]; then
        echo "✅ Services stopped successfully"
    else
        echo "❌ Failed to stop services"
        exit 1
    fi
}

# Function to restart services
restart_services() {
    echo "Restarting RX-DEX services..."
    docker-compose -f docker-compose.prod.yml down
    sleep 5
    docker-compose -f docker-compose.prod.yml up -d
    if [[ $? -eq 0 ]]; then
        echo "✅ Services restarted successfully"
    else
        echo "❌ Failed to restart services"
        exit 1
    fi
}

# Function to check service status
check_status() {
    echo "Checking RX-DEX service status..."
    docker-compose -f docker-compose.prod.yml ps
}

# Function to view logs
view_logs() {
    echo "Viewing RX-DEX service logs..."
    echo "Press Ctrl+C to exit log view"
    sleep 2
    docker-compose -f docker-compose.prod.yml logs -f
}

# Function to update services
update_services() {
    echo "Updating RX-DEX services..."
    
    # Pull latest code
    echo "Pulling latest code from repository..."
    git pull
    if [[ $? -ne 0 ]]; then
        echo "❌ Failed to pull latest code"
        exit 1
    fi
    
    # Rebuild and restart services
    echo "Rebuilding and restarting services..."
    docker-compose -f docker-compose.prod.yml up -d --build
    if [[ $? -eq 0 ]]; then
        echo "✅ Services updated successfully"
    else
        echo "❌ Failed to update services"
        exit 1
    fi
}

# Function to backup database
backup_database() {
    echo "Creating database backup..."
    DATE=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="backup_$DATE.sql"
    
    docker-compose -f docker-compose.prod.yml exec postgres pg_dump -U $POSTGRES_USER $POSTGRES_DB > $BACKUP_FILE
    
    if [[ $? -eq 0 ]]; then
        echo "✅ Database backup created: $BACKUP_FILE"
    else
        echo "❌ Failed to create database backup"
        exit 1
    fi
}

# Function to monitor resources
monitor_resources() {
    echo "Monitoring system resources..."
    echo "Press Ctrl+C to exit monitoring"
    sleep 2
    docker stats
}

# Function to show help
show_help() {
    echo "RX-DEX Daily Production Operations Script"
    echo ""
    echo "Usage: ./scripts/daily-prod.sh [command]"
    echo ""
    echo "Commands:"
    echo "  start     - Start all services"
    echo "  stop      - Stop all services"
    echo "  restart   - Restart all services"
    echo "  status    - Check service status"
    echo "  logs      - View service logs"
    echo "  update    - Update services to latest version"
    echo "  backup    - Create database backup"
    echo "  monitor   - Monitor system resources"
    echo "  help      - Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./scripts/daily-prod.sh start"
    echo "  ./scripts/daily-prod.sh status"
    echo "  ./scripts/daily-prod.sh logs"
}

# Main script logic
main() {
    check_privileges
    check_requirements
    
    case "$1" in
        start)
            load_env
            start_services
            ;;
        stop)
            load_env
            stop_services
            ;;
        restart)
            load_env
            restart_services
            ;;
        status)
            load_env
            check_status
            ;;
        logs)
            load_env
            view_logs
            ;;
        update)
            load_env
            update_services
            ;;
        backup)
            load_env
            backup_database
            ;;
        monitor)
            monitor_resources
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