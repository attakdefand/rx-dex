#!/bin/bash

# Production Setup Script for RX-DEX
# This script sets up the RX-DEX platform for production deployment

echo "========================================"
echo "  RX-DEX Production Setup"
echo "========================================"
echo ""

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root" 1>&2
        exit 1
    fi
}

# Function to check system requirements
check_requirements() {
    echo "Checking system requirements..."
    
    # Check Ubuntu/Debian
    if ! command -v apt &> /dev/null; then
        echo "❌ This script requires Ubuntu/Debian-based system"
        exit 1
    fi
    
    # Check minimum requirements
    TOTAL_MEM=$(free -g | awk '/^Mem:/{print $2}')
    CPU_CORES=$(nproc)
    
    if [[ $TOTAL_MEM -lt 16 ]]; then
        echo "⚠️  Warning: Recommended minimum RAM is 16GB (Current: ${TOTAL_MEM}GB)"
    else
        echo "✅ Memory: ${TOTAL_MEM}GB"
    fi
    
    if [[ $CPU_CORES -lt 4 ]]; then
        echo "⚠️  Warning: Recommended minimum CPU cores is 4 (Current: ${CPU_CORES})"
    else
        echo "✅ CPU Cores: ${CPU_CORES}"
    fi
    
    echo ""
}

# Function to update system
update_system() {
    echo "Updating system packages..."
    apt update && apt upgrade -y
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
    
    # Install prerequisites
    apt install apt-transport-https ca-certificates curl software-properties-common -y
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    
    # Add Docker repository
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    
    # Update package index
    apt update
    
    # Install Docker
    apt install docker-ce -y
    
    # Start and enable Docker
    systemctl start docker
    systemctl enable docker
    
    # Add current user to docker group
    usermod -aG docker $SUDO_USER
    
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
    
    # Install Docker Compose
    curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
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
    
    apt install nginx -y
    
    if [[ $? -ne 0 ]]; then
        echo "❌ Failed to install Nginx"
        exit 1
    fi
    
    systemctl start nginx
    systemctl enable nginx
    
    echo "✅ Nginx installed"
    echo ""
}

# Function to install Certbot
install_certbot() {
    echo "Installing Certbot..."
    
    apt install certbot python3-certbot-nginx -y
    
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
    
    # Install UFW if not present
    apt install ufw -y
    
    # Configure firewall rules
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow 'Nginx Full'
    
    # Enable firewall
    echo "y" | ufw enable
    
    echo "✅ Firewall configured"
    echo ""
}

# Function to create log directory
create_log_directory() {
    echo "Creating log directory..."
    
    mkdir -p /var/log/rx-dex
    chown $SUDO_USER:$SUDO_USER /var/log/rx-dex
    
    echo "✅ Log directory created"
    echo ""
}

# Function to show completion message
show_completion() {
    echo "========================================"
    echo "  RX-DEX Production Setup Complete!"
    echo "========================================"
    echo ""
    echo "Next steps:"
    echo "1. Log out and log back in to apply Docker group membership"
    echo "2. Clone the RX-DEX repository"
    echo "3. Configure .env.prod file with your settings"
    echo "4. Configure nginx for your domain (toklo.xyz)"
    echo "5. Obtain SSL certificate with Certbot"
    echo "6. Start services with: ./scripts/daily-prod.sh start"
    echo ""
    echo "For detailed instructions, see PRODUCTION-HOSTING-GUIDE.md"
    echo ""
}

# Function to show help
show_help() {
    echo "RX-DEX Production Setup Script"
    echo ""
    echo "Usage: sudo ./scripts/setup-prod.sh [option]"
    echo ""
    echo "Options:"
    echo "  all       - Run complete setup (default)"
    echo "  docker    - Install only Docker and Docker Compose"
    echo "  nginx     - Install only Nginx"
    echo "  certbot   - Install only Certbot"
    echo "  firewall  - Configure only firewall"
    echo "  help      - Show this help message"
    echo ""
    echo "Examples:"
    echo "  sudo ./scripts/setup-prod.sh"
    echo "  sudo ./scripts/setup-prod.sh docker"
}

# Main script logic
main() {
    check_root
    check_requirements
    
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