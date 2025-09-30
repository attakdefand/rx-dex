#!/bin/bash

# Production Monitoring Script for RX-DEX
# This script provides comprehensive monitoring for the RX-DEX production environment

echo "========================================"
echo "  RX-DEX Production Monitoring"
echo "========================================"
echo ""

# Function to check if required files exist
check_requirements() {
    if [[ ! -f ".env.prod" ]]; then
        echo "❌ Error: .env.prod file not found!"
        exit 1
    fi
    
    if [[ ! -f "docker-compose.prod.yml" ]]; then
        echo "❌ Error: docker-compose.prod.yml file not found!"
        exit 1
    fi
}

# Function to load environment variables
load_env() {
    export $(cat .env.prod | xargs)
}

# Function to check service status
check_service_status() {
    echo "=== Service Status ==="
    docker-compose -f docker-compose.prod.yml ps
    echo ""
}

# Function to check system resources
check_system_resources() {
    echo "=== System Resources ==="
    echo "CPU Usage:"
    top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1
    echo ""
    
    echo "Memory Usage:"
    free -h | grep "Mem" | awk '{print "Used: " $3 ", Free: " $4 ", Total: " $2}'
    echo ""
    
    echo "Disk Usage:"
    df -h / | grep -v "Filesystem" | awk '{print "Used: " $3 ", Available: " $4 ", Usage: " $5}'
    echo ""
}

# Function to check Docker resources
check_docker_resources() {
    echo "=== Docker Resources ==="
    echo "Running Containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    
    echo "Container Resource Usage:"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
    echo ""
}

# Function to check database status
check_database_status() {
    echo "=== Database Status ==="
    DB_STATUS=$(docker-compose -f docker-compose.prod.yml exec postgres pg_isready 2>/dev/null)
    if [[ $? -eq 0 ]]; then
        echo "✅ PostgreSQL: Running"
    else
        echo "❌ PostgreSQL: Not responding"
    fi
    
    # Check database size
    DB_SIZE=$(docker-compose -f docker-compose.prod.yml exec postgres psql -U $POSTGRES_USER -d $POSTGRES_DB -c "SELECT pg_size_pretty(pg_database_size('$POSTGRES_DB'));" 2>/dev/null | grep -v "pg_size_pretty" | grep -v "^$" | head -1)
    echo "Database Size: $DB_SIZE"
    echo ""
}

# Function to check Redis status
check_redis_status() {
    echo "=== Redis Status ==="
    REDIS_STATUS=$(docker-compose -f docker-compose.prod.yml exec redis redis-cli ping 2>/dev/null)
    if [[ "$REDIS_STATUS" == "PONG" ]]; then
        echo "✅ Redis: Running"
    else
        echo "❌ Redis: Not responding"
    fi
    
    # Check Redis info
    REDIS_INFO=$(docker-compose -f docker-compose.prod.yml exec redis redis-cli info 2>/dev/null | grep "connected_clients" | cut -d':' -f2)
    echo "Connected Clients: $REDIS_INFO"
    echo ""
}

# Function to check API gateway health
check_api_health() {
    echo "=== API Health Check ==="
    API_STATUS=$(curl -s -f -m 5 http://localhost:8080/health 2>/dev/null)
    if [[ $? -eq 0 ]]; then
        echo "✅ API Gateway: OK"
    else
        echo "❌ API Gateway: Not responding"
    fi
    
    WEB_STATUS=$(curl -s -f -m 5 http://localhost:8082 2>/dev/null)
    if [[ $? -eq 0 ]]; then
        echo "✅ Web Frontend: OK"
    else
        echo "❌ Web Frontend: Not responding"
    fi
    echo ""
}

# Function to check recent logs
check_recent_logs() {
    echo "=== Recent Error Logs ==="
    echo "Last 10 lines from each service:"
    SERVICES=("api-gateway" "quoter" "order-service" "user-service" "matching-engine" "wallet-service" "notification-service" "admin-service" "trading-service" "web")
    
    for service in "${SERVICES[@]}"; do
        echo "--- $service ---"
        docker-compose -f docker-compose.prod.yml logs --tail=10 $service 2>/dev/null | grep -i "error\|warn\|fail" || echo "No errors found"
        echo ""
    done
}

# Function to generate monitoring report
generate_report() {
    echo "=== Monitoring Report Summary ==="
    TIMESTAMP=$(date)
    echo "Report generated at: $TIMESTAMP"
    echo ""
    
    # Count running services
    RUNNING_SERVICES=$(docker-compose -f docker-compose.prod.yml ps | grep "Up" | wc -l)
    TOTAL_SERVICES=$(docker-compose -f docker-compose.prod.yml ps | wc -l)
    TOTAL_SERVICES=$((TOTAL_SERVICES - 2)) # Subtract header lines
    
    echo "Services: $RUNNING_SERVICES/$TOTAL_SERVICES running"
    
    # Check system load
    LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | xargs)
    echo "System Load: $LOAD_AVG"
    
    # Check memory usage percentage
    MEM_USAGE=$(free | grep Mem | awk '{printf("%.2f%%"), $3/$2 * 100.0}')
    echo "Memory Usage: $MEM_USAGE"
    
    # Check disk usage percentage
    DISK_USAGE=$(df / | grep -v "Filesystem" | awk '{print $5}' | sed 's/%//')
    if [[ $DISK_USAGE -gt 90 ]]; then
        echo "⚠️  Disk Usage: ${DISK_USAGE}% (High)"
    elif [[ $DISK_USAGE -gt 75 ]]; then
        echo "⚠️  Disk Usage: ${DISK_USAGE}% (Medium)"
    else
        echo "✅ Disk Usage: ${DISK_USAGE}% (Normal)"
    fi
    
    echo ""
    echo "=== End of Report ==="
}

# Function to show help
show_help() {
    echo "RX-DEX Production Monitoring Script"
    echo ""
    echo "Usage: ./scripts/monitor-prod.sh [option]"
    echo ""
    echo "Options:"
    echo "  all       - Run all monitoring checks (default)"
    echo "  status    - Check service status"
    echo "  resources - Check system and Docker resources"
    echo "  database  - Check database status"
    echo "  redis     - Check Redis status"
    echo "  api       - Check API health"
    echo "  logs      - Check recent logs"
    echo "  report    - Generate monitoring report"
    echo "  help      - Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./scripts/monitor-prod.sh"
    echo "  ./scripts/monitor-prod.sh status"
    echo "  ./scripts/monitor-prod.sh report"
}

# Main script logic
main() {
    check_requirements
    load_env
    
    case "$1" in
        status)
            check_service_status
            ;;
        resources)
            check_system_resources
            check_docker_resources
            ;;
        database)
            check_database_status
            ;;
        redis)
            check_redis_status
            ;;
        api)
            check_api_health
            ;;
        logs)
            check_recent_logs
            ;;
        report)
            generate_report
            ;;
        help|"")
            if [[ -z "$1" ]]; then
                check_service_status
                check_system_resources
                check_docker_resources
                check_database_status
                check_redis_status
                check_api_health
                generate_report
            else
                show_help
            fi
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"