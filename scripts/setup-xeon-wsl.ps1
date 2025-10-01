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

# Function to install required packages
function Install-Packages {
    Write-Host "Installing required packages..." -ForegroundColor Cyan
    
    try {
        # Install prerequisites
        wsl sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
        
        # Install monitoring tools
        wsl sudo apt install htop iotop iftop -y
        
        Write-Host "✅ Required packages installed" -ForegroundColor Green
        Write-Host ""
    } catch {
        Write-Host "❌ Failed to install required packages" -ForegroundColor Red
        exit 1
    }
}

# Function to configure Docker Desktop integration
function Configure-DockerDesktop {
    Write-Host "Configuring Docker Desktop integration..." -ForegroundColor Cyan
    
    try {
        # Create Docker config directory
        wsl mkdir -p ~/.docker
        
        # Configure Docker CLI to connect to Docker Desktop
        @"
{
    "experimental": "enabled",
    "stackOrchestrator": "swarm"
}
"@ | wsl tee ~/.docker/config.json > $null
        
        # Test Docker connection
        $dockerTest = wsl docker version 2>$null
        if (-not $dockerTest) {
            Write-Host "⚠️  Docker is not accessible from WSL" -ForegroundColor Yellow
            Write-Host "   Please ensure Docker Desktop is installed and running on Windows" -ForegroundColor Yellow
            Write-Host "   Also make sure WSL integration is enabled in Docker Desktop settings" -ForegroundColor Yellow
            Write-Host "   Visit: https://docs.docker.com/go/wsl2/ for more details" -ForegroundColor Yellow
            Write-Host ""
        } else {
            Write-Host "✅ Docker Desktop integration configured" -ForegroundColor Green
            wsl docker version
            Write-Host ""
        }
    } catch {
        Write-Host "❌ Failed to configure Docker Desktop integration" -ForegroundColor Red
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

# Function to build Docker images (using Docker Desktop)
function Build-DockerImages {
    Write-Host "Building Docker images with Docker Desktop..." -ForegroundColor Cyan
    
    try {
        # Check if Docker is accessible
        $dockerTest = wsl docker version 2>$null
        if (-not $dockerTest) {
            Write-Host "⚠️  Docker is not accessible from WSL" -ForegroundColor Yellow
            Write-Host "   Please ensure Docker Desktop is installed and running on Windows" -ForegroundColor Yellow
            Write-Host "   Also make sure WSL integration is enabled in Docker Desktop settings" -ForegroundColor Yellow
            Write-Host "   Visit: https://docs.docker.com/go/wsl2/ for more details" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Skipping Docker image build. You can build images later with:" -ForegroundColor Yellow
            Write-Host "   docker-compose -f docker-compose.wsl.yml build" -ForegroundColor Yellow
            Write-Host ""
            return
        }
        
        # Build images using the WSL-specific docker-compose file
        Write-Host "Building Docker images using docker-compose.wsl.yml..." -ForegroundColor Cyan
        wsl docker-compose -f docker-compose.wsl.yml build
        
        Write-Host "✅ Docker images built successfully" -ForegroundColor Green
        Write-Host ""
    } catch {
        Write-Host "❌ Failed to build Docker images" -ForegroundColor Red
        Write-Host "   You can try building images later with: docker-compose -f docker-compose.wsl.yml build" -ForegroundColor Yellow
        Write-Host ""
    }
}

# Function to make scripts executable
function Make-ScriptsExecutable {
    Write-Host "Making scripts executable..." -ForegroundColor Cyan
    
    try {
        Get-ChildItem -Path "./scripts" -Filter "*.sh" | ForEach-Object {
            wsl chmod +x $_.FullName
        }
        
        Write-Host "✅ Scripts made executable" -ForegroundColor Green
        Write-Host ""
    } catch {
        Write-Host "❌ Failed to make scripts executable" -ForegroundColor Red
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
    Write-Host "1. Ensure Docker Desktop is installed and running on Windows" -ForegroundColor White
    Write-Host "2. Enable WSL integration in Docker Desktop settings" -ForegroundColor White
    Write-Host "3. Start services with: ./scripts/daily-dev-wsl.sh" -ForegroundColor White
    Write-Host "4. In another terminal, start the web frontend: cd clients/web && trunk serve --port 8082" -ForegroundColor White
    Write-Host "5. Check service status with: ./scripts/daily-health-check-wsl.sh" -ForegroundColor White
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
    Write-Host "  all           - Run complete setup (default)" -ForegroundColor White
    Write-Host "  docker        - Install Docker and configure Docker Desktop integration" -ForegroundColor White
    Write-Host "  packages      - Install required packages" -ForegroundColor White
    Write-Host "  docker-config - Configure Docker Desktop integration" -ForegroundColor White
    Write-Host "  env           - Create only environment file" -ForegroundColor White
    Write-Host "  build         - Build Docker images" -ForegroundColor White
    Write-Host "  help          - Show this help message" -ForegroundColor White
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
            Install-Packages
            Configure-DockerDesktop
        }
        "packages" {
            Install-Packages
        }
        "docker-config" {
            Configure-DockerDesktop
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
            Install-Packages
            Configure-DockerDesktop
            Create-LogDirectory
            Create-EnvFile
            Make-ScriptsExecutable
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