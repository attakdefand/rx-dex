#!/bin/bash

# Xeon Server Simulation Setup Script for WSL
# This script sets up the RX-DEX platform in a WSL environment to simulate Xeon server deployment

echo "========================================"
echo "  RX-DEX Xeon Server Simulation Setup"
echo "========================================"
echo ""

# Function to check if running in WSL
check_wsl() {
    if [[ ! -f /proc/version ]] || ! grep -q Microsoft /proc/version; then
        echo "⚠️  Warning: This script is designed for WSL environment"
        echo "   Some features may not work as expected on native Linux"
    fi
}

# Function to update system
update_system() {
    echo "Updating system packages..."
    sudo apt update && sudo apt upgrade -y
    if [[ $? -ne 0 ]]; then
        echo "❌ Failed to update system packages"
        exit 1
    fi
    echo "✅ System packages updated"
    echo ""
}

# Function to install required packages
install_packages() {
    echo "Installing required packages..."
    
    # Install prerequisites
    sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
    
    # Install monitoring tools
    sudo apt install htop iotop iftop -y
    
    if [[ $? -ne 0 ]]; then
        echo "❌ Failed to install required packages"
        exit 1
    fi
    
    echo "✅ Required packages installed"
    echo ""
}

# Function to configure Docker Desktop integration
configure_docker_desktop() {
    echo "Configuring Docker Desktop integration..."
    
    # Create Docker config directory
    mkdir -p ~/.docker
    
    # Configure Docker CLI to connect to Docker Desktop
    cat > ~/.docker/config.json << EOF
{
    "experimental": "enabled",
    "stackOrchestrator": "swarm"
}
EOF
    
    # Test Docker connection
    if ! docker version >/dev/null 2>&1; then
        echo "⚠️  Docker is not accessible from WSL"
        echo "   Please ensure Docker Desktop is installed and running on Windows"
        echo "   Also make sure WSL integration is enabled in Docker Desktop settings"
        echo "   Visit: https://docs.docker.com/go/wsl2/ for more details"
        echo ""
    else
        echo "✅ Docker Desktop integration configured"
        docker version
        echo ""
    fi
}

# Function to create log directory
create_log_directory() {
    echo "Creating log directory..."
    
    sudo mkdir -p /var/log/rx-dex
    sudo chown $USER:$USER /var/log/rx-dex
    
    echo "✅ Log directory created"
    echo ""
}

# Function to create production environment file
create_env_file() {
    echo "Creating production environment file..."
    
    if [[ -f ".env.prod" ]]; then
        echo "⚠️  .env.prod already exists, skipping creation"
        echo ""
        return
    fi
    
    cat > .env.prod << EOF
# RX-DEX Production Environment Configuration

# Database Configuration
POSTGRES_DB=rxdex
POSTGRES_USER=rxdex
POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d /=+ | cut -c -20)

# Redis Configuration
REDIS_URL=redis://redis:6379

# Service URLs (used by API Gateway)
QUOTER_URL=http://quoter:8081
USER_SERVICE_URL=http://user-service:8084
ORDER_SERVICE_URL=http://order-service:8083
ADMIN_SERVICE_URL=http://admin-service:8088
TRADING_SERVICE_URL=http://trading-service:8089

# Additional Configuration
RUST_LOG=info
EOF
    
    echo "✅ Production environment file created"
    echo "   Note: A random password has been generated for PostgreSQL"
    echo "   You can view it by running: cat .env.prod"
    echo ""
}

# Function to build Docker images (using Docker Desktop)
build_docker_images() {
    echo "Building Docker images with Docker Desktop..."
    
    # Check if Docker is accessible
    if ! docker version >/dev/null 2>&1; then
        echo "⚠️  Docker is not accessible from WSL"
        echo "   Please ensure Docker Desktop is installed and running on Windows"
        echo "   Also make sure WSL integration is enabled in Docker Desktop settings"
        echo "   Visit: https://docs.docker.com/go/wsl2/ for more details"
        echo ""
        echo "Skipping Docker image build. You can build images later with:"
        echo "   docker-compose -f docker-compose.wsl.yml build"
        echo ""
        return
    fi
    
    # Build images using the WSL-specific docker-compose file
    echo "Building Docker images using docker-compose.wsl.yml..."
    docker-compose -f docker-compose.wsl.yml build
    
    if [[ $? -ne 0 ]]; then
        echo "❌ Failed to build Docker images"
        echo "   You can try building images later with: docker-compose -f docker-compose.wsl.yml build"
        echo ""
    else
        echo "✅ Docker images built successfully"
        echo ""
    fi
}

# Function to make scripts executable
make_scripts_executable() {
    echo "Making scripts executable..."
    
    # Make all shell scripts in the scripts directory executable
    find scripts -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    
    echo "✅ Scripts made executable"
    echo ""
}

# Function to show completion message
show_completion() {
    echo "========================================"
    echo "  RX-DEX Xeon Server Simulation Setup Complete!"
    echo "========================================"
    echo ""
    echo "Your WSL environment is now configured to simulate a Xeon server deployment."
    echo ""
    echo "Next steps:"
    echo "1. Ensure Docker Desktop is installed and running on Windows"
    echo "2. Enable WSL integration in Docker Desktop settings"
    echo "3. Start services with: ./scripts/daily-dev-wsl.sh"
    echo "4. In another terminal, start the web frontend: cd clients/web && trunk serve --port 8082"
    echo "5. Check service status with: ./scripts/daily-health-check-wsl.sh"
    echo ""
    echo "For production deployment on your actual Xeon server, follow the"
    echo "PRODUCTION-DEPLOYMENT-GUIDE.md file."
    echo ""
}

# Function to show help
show_help() {
    echo "RX-DEX Xeon Server Simulation Setup Script"
    echo ""
    echo "Usage: ./scripts/setup-xeon-wsl.sh [option]"
    echo ""
    echo "Options:"
    echo "  all       - Run complete setup (default)"
    echo "  docker    - Install only Docker and Docker Compose"
    echo "  nginx     - Install only Nginx"
    echo "  certbot   - Install only Certbot"
    echo "  firewall  - Configure only firewall"
    echo "  env       - Create only environment file"
    echo "  build     - Build Docker images"
    echo "  help      - Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./scripts/setup-xeon-wsl.sh"
    echo "  ./scripts/setup-xeon-wsl.sh docker"
}

# Main script logic
main() {
    check_wsl
    
    case "$1" in
        docker)
            update_system
            install_packages
            configure_docker_desktop
            ;;
        packages)
            install_packages
            ;;
        docker-config)
            configure_docker_desktop
            ;;
        env)
            create_env_file
            ;;
        build)
            build_docker_images
            ;;
        help)
            show_help
            ;;
        ""|all)
            update_system
            install_packages
            configure_docker_desktop
            create_log_directory
            create_env_file
            make_scripts_executable
            build_docker_images
            show_completion
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