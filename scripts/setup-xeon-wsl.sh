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

# Function to install Docker
install_docker() {
    echo "Installing Docker..."
    
    # Check if Docker is already installed
    if command -v docker &> /dev/null; then
        echo "✅ Docker is already installed"
        docker --version
        echo ""
        return
    fi
    
    # Install prerequisites
    sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    
    # Add Docker repository
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    
    # Update package index
    sudo apt update
    
    # Install Docker
    sudo apt install docker-ce -y
    
    # Start and enable Docker
    sudo service docker start
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    if [[ $? -ne 0 ]]; then
        echo "❌ Failed to install Docker"
        exit 1
    fi
    
    echo "✅ Docker installed"
    echo ""
}

# Function to install Docker Compose
install_docker_compose() {
    echo "Installing Docker Compose..."
    
    # Check if Docker Compose is already installed
    if command -v docker-compose &> /dev/null; then
        echo "✅ Docker Compose is already installed"
        docker-compose --version
        echo ""
        return
    fi
    
    # Install Docker Compose
    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    if [[ $? -ne 0 ]]; then
        echo "❌ Failed to install Docker Compose"
        exit 1
    fi
    
    echo "✅ Docker Compose installed"
    echo ""
}

# Function to install Nginx
install_nginx() {
    echo "Installing Nginx..."
    
    # Check if Nginx is already installed
    if command -v nginx &> /dev/null; then
        echo "✅ Nginx is already installed"
        nginx -v
        echo ""
        return
    fi
    
    sudo apt install nginx -y
    
    if [[ $? -ne 0 ]]; then
        echo "❌ Failed to install Nginx"
        exit 1
    fi
    
    echo "✅ Nginx installed"
    echo ""
}

# Function to install Certbot
install_certbot() {
    echo "Installing Certbot..."
    
    # Check if Certbot is already installed
    if command -v certbot &> /dev/null; then
        echo "✅ Certbot is already installed"
        certbot --version
        echo ""
        return
    fi
    
    sudo apt install certbot python3-certbot-nginx -y
    
    if [[ $? -ne 0 ]]; then
        echo "❌ Failed to install Certbot"
        exit 1
    fi
    
    echo "✅ Certbot installed"
    echo ""
}

# Function to setup firewall
setup_firewall() {
    echo "Setting up firewall..."
    
    # Check if UFW is installed
    if ! command -v ufw &> /dev/null; then
        sudo apt install ufw -y
    fi
    
    # Configure firewall rules
    echo "y" | sudo ufw enable >/dev/null 2>&1
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw allow 'Nginx Full'
    
    echo "✅ Firewall configured"
    echo ""
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

# Function to build Docker images
build_docker_images() {
    echo "Building Docker images..."
    
    # Check if Docker daemon is running
    if ! sudo service docker status >/dev/null 2>&1; then
        echo "Starting Docker daemon..."
        sudo service docker start
    fi
    
    # Build images
    docker-compose -f docker-compose.prod.yml build
    
    if [[ $? -ne 0 ]]; then
        echo "❌ Failed to build Docker images"
        exit 1
    fi
    
    echo "✅ Docker images built successfully"
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
    echo "1. Log out and log back in to apply Docker group membership"
    echo "2. Start services with: ./scripts/daily-prod.sh start"
    echo "3. Check service status with: ./scripts/daily-prod.sh status"
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
            install_docker
            install_docker_compose
            ;;
        nginx)
            install_nginx
            ;;
        certbot)
            install_certbot
            ;;
        firewall)
            setup_firewall
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
            install_docker
            install_docker_compose
            install_nginx
            install_certbot
            setup_firewall
            create_log_directory
            create_env_file
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