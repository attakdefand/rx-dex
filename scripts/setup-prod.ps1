# Production Setup Script for RX-DEX
# This script sets up the RX-DEX platform for production deployment

Write-Host "========================================"
Write-Host "  RX-DEX Production Setup"
Write-Host "========================================"
Write-Host ""

# Function to check if running as administrator
function Check-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host "This script must be run as Administrator" -ForegroundColor Red
        exit 1
    }
}

# Function to check system requirements
function Check-Requirements {
    Write-Host "Checking system requirements..." -ForegroundColor Yellow
    
    # Check Windows version (simplified)
    $os = Get-WmiObject -Class Win32_OperatingSystem
    Write-Host "✅ Operating System: $($os.Caption)" -ForegroundColor Green
    
    # Check minimum requirements
    $totalMem = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $cpuCores = (Get-WmiObject -Class Win32_Processor).NumberOfCores
    
    if ($totalMem -lt 16) {
        Write-Host "⚠️  Warning: Recommended minimum RAM is 16GB (Current: ${totalMem}GB)" -ForegroundColor Yellow
    } else {
        Write-Host "✅ Memory: ${totalMem}GB" -ForegroundColor Green
    }
    
    if ($cpuCores -lt 4) {
        Write-Host "⚠️  Warning: Recommended minimum CPU cores is 4 (Current: ${cpuCores})" -ForegroundColor Yellow
    } else {
        Write-Host "✅ CPU Cores: ${cpuCores}" -ForegroundColor Green
    }
    
    Write-Host ""
}

# Function to install Docker Desktop
function Install-DockerDesktop {
    Write-Host "Installing Docker Desktop..." -ForegroundColor Yellow
    
    # Check if Docker is already installed
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        Write-Host "✅ Docker is already installed" -ForegroundColor Green
        return
    }
    
    # Download Docker Desktop installer
    Write-Host "Downloading Docker Desktop..." -ForegroundColor Cyan
    $dockerUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
    $installerPath = "$env:TEMP\DockerDesktopInstaller.exe"
    
    try {
        Invoke-WebRequest -Uri $dockerUrl -OutFile $installerPath
        Write-Host "✅ Docker Desktop downloaded" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to download Docker Desktop" -ForegroundColor Red
        Write-Host "Please download and install Docker Desktop manually from https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
        return
    }
    
    # Install Docker Desktop
    Write-Host "Installing Docker Desktop..." -ForegroundColor Cyan
    Start-Process -FilePath $installerPath -ArgumentList "install", "--quiet" -Wait
    
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        Write-Host "✅ Docker Desktop installed" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to install Docker Desktop" -ForegroundColor Red
        Write-Host "Please install Docker Desktop manually from https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    }
    
    Write-Host ""
}

# Function to install required tools
function Install-Tools {
    Write-Host "Installing required tools..." -ForegroundColor Yellow
    
    # Install Chocolatey if not present
    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "Installing Chocolatey..." -ForegroundColor Cyan
        Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    }
    
    # Install required tools
    Write-Host "Installing Nginx..." -ForegroundColor Cyan
    choco install nginx -y
    
    Write-Host "Installing Git..." -ForegroundColor Cyan
    choco install git -y
    
    Write-Host "✅ Required tools installed" -ForegroundColor Green
    Write-Host ""
}

# Function to setup firewall
function Setup-Firewall {
    Write-Host "Setting up firewall..." -ForegroundColor Yellow
    
    # Enable required firewall rules
    try {
        # Enable SSH (if needed)
        # Enable HTTP/HTTPS
        netsh advfirewall firewall add rule name="HTTP" dir=in action=allow protocol=TCP localport=80
        netsh advfirewall firewall add rule name="HTTPS" dir=in action=allow protocol=TCP localport=443
        netsh advfirewall firewall add rule name="Docker" dir=in action=allow protocol=TCP localport=2375
        
        Write-Host "✅ Firewall configured" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to configure firewall" -ForegroundColor Red
        Write-Host "Please configure firewall manually to allow HTTP (80), HTTPS (443), and Docker (2375)" -ForegroundColor Yellow
    }
    
    Write-Host ""
}

# Function to create log directory
function Create-LogDirectory {
    Write-Host "Creating log directory..." -ForegroundColor Yellow
    
    $logPath = "C:\logs\rx-dex"
    if (!(Test-Path $logPath)) {
        New-Item -ItemType Directory -Path $logPath -Force
        Write-Host "✅ Log directory created at $logPath" -ForegroundColor Green
    } else {
        Write-Host "✅ Log directory already exists at $logPath" -ForegroundColor Green
    }
    
    Write-Host ""
}

# Function to show completion message
function Show-Completion {
    Write-Host "========================================"
    Write-Host "  RX-DEX Production Setup Complete!"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Restart your computer to complete Docker installation" -ForegroundColor White
    Write-Host "2. Clone the RX-DEX repository" -ForegroundColor White
    Write-Host "3. Configure .env.prod file with your settings" -ForegroundColor White
    Write-Host "4. Configure nginx for your domain (toklo.xyz)" -ForegroundColor White
    Write-Host "5. Obtain SSL certificate" -ForegroundColor White
    Write-Host "6. Start services with: .\scripts\daily-prod.ps1 start" -ForegroundColor White
    Write-Host ""
    Write-Host "For detailed instructions, see PRODUCTION-HOSTING-GUIDE.md" -ForegroundColor Cyan
    Write-Host ""
}

# Function to show help
function Show-Help {
    Write-Host "RX-DEX Production Setup Script" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: .\scripts\setup-prod.ps1 [option]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Cyan
    Write-Host "  all       - Run complete setup (default)" -ForegroundColor White
    Write-Host "  docker    - Install only Docker Desktop" -ForegroundColor White
    Write-Host "  tools     - Install only required tools" -ForegroundColor White
    Write-Host "  firewall  - Configure only firewall" -ForegroundColor White
    Write-Host "  help      - Show this help message" -ForegroundColor White
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Cyan
    Write-Host "  .\scripts\setup-prod.ps1" -ForegroundColor White
    Write-Host "  .\scripts\setup-prod.ps1 docker" -ForegroundColor White
}

# Main script logic
function Main {
    Check-Admin
    Check-Requirements
    
    $option = $args[0]
    
    switch ($option) {
        "docker" {
            Install-DockerDesktop
        }
        "tools" {
            Install-Tools
        }
        "firewall" {
            Setup-Firewall
        }
        "help" {
            Show-Help
        }
        "" {
            Install-DockerDesktop
            Install-Tools
            Setup-Firewall
            Create-LogDirectory
            Show-Completion
        }
        default {
            Write-Host "Unknown option: $option" -ForegroundColor Red
            Show-Help
        }
    }
}

# Run main function with all arguments
Main @args