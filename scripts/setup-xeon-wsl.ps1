# Xeon Server Simulation Setup Script for WSL (PowerShell Version)
# This script sets up the RX-DEX platform in a WSL environment to simulate Xeon server deployment

Write-Host "========================================" -ForegroundColor Green
Write-Host "  RX-DEX Xeon Server Simulation Setup" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Function to check if running in WSL
function Check-WSL {
    if (-not (Test-Path /proc/version) -or -not (Get-Content /proc/version | Select-String -Pattern "Microsoft")) {
        Write-Host "⚠️  Warning: This script is designed for WSL environment" -ForegroundColor Yellow
        Write-Host "   Some features may not work as expected on native Linux" -ForegroundColor Yellow
    }
}

# Function to update system
function Update-System {
    Write-Host "Updating system packages..." -ForegroundColor Cyan
    try {
        wsl -u root apt update
        wsl -u root apt upgrade -y
        Write-Host "✅ System packages updated" -ForegroundColor Green
        Write-Host ""
    } catch {
        Write-Host "❌ Failed to update system packages" -ForegroundColor Red
        exit 1
    }
}

# Function to install Docker
function Install-Docker {
    Write-Host "Installing Docker..." -ForegroundColor Cyan
    
    # Check if Docker is already installed
    try {
        $dockerVersion = wsl docker --version
        Write-Host "✅ Docker is already installed" -ForegroundColor Green
        Write-Host $dockerVersion -ForegroundColor Gray
        Write-Host ""
        return
    } catch {
        # Docker not installed, continue with installation
    }
    
    try {
        # Install prerequisites
        wsl -u root apt install apt-transport-https ca-certificates curl software-properties-common -y
        
        # Add Docker's official GPG key
        wsl curl -fsSL https://download.docker.com/linux/ubuntu/gpg | wsl -u root apt-key add -
        
        # Add Docker repository
        wsl -u root add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(wsl lsb_release -cs) stable"
        
        # Update package index
        wsl -u root apt update
        
        # Install Docker
        wsl -u root apt install docker-ce -y
        
        # Start and enable Docker
        wsl -u root service docker start
        
        # Add current user to docker group
        wsl -u root usermod -aG docker $env:USER
        
        Write-Host "✅ Docker installed" -ForegroundColor Green
        Write-Host ""
    } catch {
        Write-Host "❌ Failed to install Docker" -ForegroundColor Red
        exit 1
    }
}

# Function to install Docker Compose
function Install-DockerCompose {
    Write-Host "Installing Docker Compose..." -ForegroundColor Cyan
    
    # Check if Docker Compose is already installed
    try {
        $composeVersion = wsl docker-compose --version
        Write-Host "✅ Docker Compose is already installed" -ForegroundColor Green
        Write-Host $composeVersion -ForegroundColor Gray
        Write-Host ""
        return
    } catch {
        # Docker Compose not installed, continue with installation
    }
    
    try {
        # Install Docker Compose
        wsl -u root curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(wsl uname -s)-$(wsl uname -m)" -o /usr/local/bin/docker-compose
        wsl -u root chmod +x /usr/local/bin/docker-compose
        
        Write-Host "✅ Docker Compose installed" -ForegroundColor Green
        Write-Host ""
    } catch {
        Write-Host "❌ Failed to install Docker Compose" -ForegroundColor Red
        exit 1
    }
}

# Function to install Nginx
function Install-Nginx {
    Write-Host "Installing Nginx..." -ForegroundColor Cyan
    
    # Check if Nginx is already installed
    try {
        $nginxVersion = wsl nginx -v 2>&1
        Write-Host "✅ Nginx is already installed" -ForegroundColor Green
        Write-Host $nginxVersion -ForegroundColor Gray
        Write-Host ""
        return
    } catch {
        # Nginx not installed, continue with installation
    }
    
    try {
        wsl -u root apt install nginx -y
        Write-Host "✅ Nginx installed" -ForegroundColor Green
        Write-Host ""
    } catch {
        Write-Host "❌ Failed to install Nginx" -ForegroundColor Red
        exit 1
    }
}

# Function to install Certbot
function Install-Certbot {
    Write-Host "Installing Certbot..." -ForegroundColor Cyan
    
    # Check if Certbot is already installed
    try {
        $certbotVersion = wsl certbot --version
        Write-Host "✅ Certbot is already installed" -ForegroundColor Green
        Write-Host $certbotVersion -ForegroundColor Gray
        Write-Host ""
        return
    } catch {
        # Certbot not installed, continue with installation
    }
    
    try {
        wsl -u root apt install certbot python3-certbot-nginx -y
        Write-Host "✅ Certbot installed" -ForegroundColor Green
        Write-Host ""
    } catch {
        Write-Host "❌ Failed to install Certbot" -ForegroundColor Red
        exit 1
    }
}

# Function to setup firewall
function Setup-Firewall {
    Write-Host "Setting up firewall..." -ForegroundColor Cyan
    
    try {
        # Check if UFW is installed
        wsl -u root apt install ufw -y
        
        # Configure firewall rules
        wsl -u root ufw --force enable
        wsl -u root ufw default deny incoming
        wsl -u root ufw default allow outgoing
        wsl -u root ufw allow ssh
        wsl -u root ufw allow 'Nginx Full'
        
        Write-Host "✅ Firewall configured" -ForegroundColor Green
        Write-Host ""
    } catch {
        Write-Host "❌ Failed to configure firewall" -ForegroundColor Red
        exit 1
    }
}

# Function to create log directory
function Create-LogDirectory {
    Write-Host "Creating log directory..." -ForegroundColor Cyan
    
    try {
        wsl -u root mkdir -p /var/log/rx-dex
        wsl -u root chown $env:USER:$env:USER /var/log/rx-dex
        
        Write-Host "✅ Log directory created" -ForegroundColor Green
        Write-Host ""
    } catch {
        Write-Host "❌ Failed to create log directory" -ForegroundColor Red
        exit 1
    }
}

# Function to create production environment file
function Create-EnvFile {
    Write-Host "Creating production environment file..." -ForegroundColor Cyan
    
    if (Test-Path ".env.prod") {
        Write-Host "⚠️  .env.prod already exists, skipping creation" -ForegroundColor Yellow
        Write-Host ""
        return
    }
    
    try {
        # Generate a random password
        $randomPassword = -join ((65..90) + (97..122) | Get-Random -Count 20 | % {[char]$_})
        
        # Create the .env.prod file
        @"
# RX-DEX Production Environment Configuration

# Database Configuration
POSTGRES_DB=rxdex
POSTGRES_USER=rxdex
POSTGRES_PASSWORD=$randomPassword

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
"@ | Out-File -FilePath ".env.prod" -Encoding UTF8
        
        Write-Host "✅ Production environment file created" -ForegroundColor Green
        Write-Host "   Note: A random password has been generated for PostgreSQL" -ForegroundColor Yellow
        Write-Host "   You can view it by running: cat .env.prod" -ForegroundColor Yellow
        Write-Host ""
    } catch {
        Write-Host "❌ Failed to create production environment file" -ForegroundColor Red
        exit 1
    }
}

# Function to build Docker images
function Build-DockerImages {
    Write-Host "Building Docker images..." -ForegroundColor Cyan
    
    try {
        # Check if Docker daemon is running
        $dockerStatus = wsl -u root service docker status 2>$null
        if (-not $dockerStatus.Contains("running")) {
            Write-Host "Starting Docker daemon..." -ForegroundColor Cyan
            wsl -u root service docker start
        }
        
        # Build images
        wsl docker-compose -f docker-compose.prod.yml build
        
        Write-Host "✅ Docker images built successfully" -ForegroundColor Green
        Write-Host ""
    } catch {
        Write-Host "❌ Failed to build Docker images" -ForegroundColor Red
        exit 1
    }
}

# Function to show completion message
function Show-Completion {
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  RX-DEX Xeon Server Simulation Setup Complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your WSL environment is now configured to simulate a Xeon server deployment." -ForegroundColor White
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor White
    Write-Host "1. Log out and log back in to apply Docker group membership" -ForegroundColor White
    Write-Host "2. Start services with: ./scripts/daily-prod.sh start" -ForegroundColor White
    Write-Host "3. Check service status with: ./scripts/daily-prod.sh status" -ForegroundColor White
    Write-Host ""
    Write-Host "For production deployment on your actual Xeon server, follow the" -ForegroundColor White
    Write-Host "PRODUCTION-DEPLOYMENT-GUIDE.md file." -ForegroundColor White
    Write-Host ""
}

# Function to show help
function Show-Help {
    Write-Host "RX-DEX Xeon Server Simulation Setup Script" -ForegroundColor White
    Write-Host ""
    Write-Host "Usage: .\scripts\setup-xeon-wsl.ps1 [option]" -ForegroundColor White
    Write-Host ""
    Write-Host "Options:" -ForegroundColor White
    Write-Host "  all       - Run complete setup (default)" -ForegroundColor White
    Write-Host "  docker    - Install only Docker and Docker Compose" -ForegroundColor White
    Write-Host "  nginx     - Install only Nginx" -ForegroundColor White
    Write-Host "  certbot   - Install only Certbot" -ForegroundColor White
    Write-Host "  firewall  - Configure only firewall" -ForegroundColor White
    Write-Host "  env       - Create only environment file" -ForegroundColor White
    Write-Host "  build     - Build Docker images" -ForegroundColor White
    Write-Host "  help      - Show this help message" -ForegroundColor White
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor White
    Write-Host "  .\scripts\setup-xeon-wsl.ps1" -ForegroundColor White
    Write-Host "  .\scripts\setup-xeon-wsl.ps1 docker" -ForegroundColor White
}

# Main script logic
function Main {
    param(
        [string]$Option = "all"
    )
    
    Check-WSL
    
    switch ($Option) {
        "docker" {
            Update-System
            Install-Docker
            Install-DockerCompose
        }
        "nginx" {
            Install-Nginx
        }
        "certbot" {
            Install-Certbot
        }
        "firewall" {
            Setup-Firewall
        }
        "env" {
            Create-EnvFile
        }
        "build" {
            Build-DockerImages
        }
        "help" {
            Show-Help
        }
        {($_ -eq "") -or ($_ -eq "all")} {
            Update-System
            Install-Docker
            Install-DockerCompose
            Install-Nginx
            Install-Certbot
            Setup-Firewall
            Create-LogDirectory
            Create-EnvFile
            Build-DockerImages
            Show-Completion
        }
        default {
            Write-Host "Unknown option: $Option" -ForegroundColor Red
            Show-Help
            exit 1
        }
    }
}

# Run main function with command line arguments
Main -Option $args[0]