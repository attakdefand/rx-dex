# RX-DEX Start Script for PowerShell
# This script starts the complete DEX platform

Write-Host "Starting RX-DEX Platform..."

# Check if docker is installed
try {
    $dockerVersion = docker --version
    Write-Host "Docker found: $dockerVersion"
} catch {
    Write-Host "Docker is not installed. Please install Docker Desktop first."
    pause
    exit 1
}

# Navigate to the rx-dex directory
Set-Location -Path "$PSScriptRoot\..\"

# Build and start all services
Write-Host "Building and starting all services..."
docker-compose up --build -d

# Wait for services to start
Write-Host "Waiting for services to start..."
Start-Sleep -Seconds 30

# Check if services are running
Write-Host "Checking service status..."
docker-compose ps

Write-Host "RX-DEX Platform is now running!"
Write-Host "Access the web interface at: http://localhost:8082"
Write-Host "Access the API at: http://localhost:8080"

Write-Host "Press any key to continue..."
$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")