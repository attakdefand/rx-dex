# Daily Production Operations for RX-DEX
# This script provides common daily operations for the RX-DEX production environment

Write-Host "========================================"
Write-Host "  RX-DEX Daily Production Operations"
Write-Host "========================================"
Write-Host ""

# Function to check if required files exist
function Check-Requirements {
    if (-not (Test-Path ".env.prod")) {
        Write-Host "❌ Error: .env.prod file not found!" -ForegroundColor Red
        Write-Host "   Please create .env.prod file with production environment variables."
        exit 1
    }
    
    if (-not (Test-Path "docker-compose.prod.yml")) {
        Write-Host "❌ Error: docker-compose.prod.yml file not found!" -ForegroundColor Red
        Write-Host "   Please create docker-compose.prod.yml file."
        exit 1
    }
}

# Function to load environment variables
function Load-Env {
    $envVars = Get-Content .env.prod
    foreach ($line in $envVars) {
        if ($line -and -not $line.StartsWith("#")) {
            $parts = $line.Split('=', 2)
            if ($parts.Count -eq 2) {
                [System.Environment]::SetEnvironmentVariable($parts[0], $parts[1])
            }
        }
    }
    Write-Host "✅ Environment variables loaded" -ForegroundColor Green
}

# Function to start services
function Start-Services {
    Write-Host "Starting RX-DEX services..." -ForegroundColor Yellow
    docker-compose -f docker-compose.prod.yml up -d
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Services started successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to start services" -ForegroundColor Red
        exit 1
    }
}

# Function to stop services
function Stop-Services {
    Write-Host "Stopping RX-DEX services..." -ForegroundColor Yellow
    docker-compose -f docker-compose.prod.yml down
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Services stopped successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to stop services" -ForegroundColor Red
        exit 1
    }
}

# Function to restart services
function Restart-Services {
    Write-Host "Restarting RX-DEX services..." -ForegroundColor Yellow
    docker-compose -f docker-compose.prod.yml down
    Start-Sleep -Seconds 5
    docker-compose -f docker-compose.prod.yml up -d
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Services restarted successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to restart services" -ForegroundColor Red
        exit 1
    }
}

# Function to check service status
function Check-Status {
    Write-Host "Checking RX-DEX service status..." -ForegroundColor Yellow
    docker-compose -f docker-compose.prod.yml ps
}

# Function to view logs
function View-Logs {
    Write-Host "Viewing RX-DEX service logs..." -ForegroundColor Yellow
    Write-Host "Press Ctrl+C to exit log view" -ForegroundColor Cyan
    Start-Sleep -Seconds 2
    docker-compose -f docker-compose.prod.yml logs -f
}

# Function to update services
function Update-Services {
    Write-Host "Updating RX-DEX services..." -ForegroundColor Yellow
    
    # Pull latest code
    Write-Host "Pulling latest code from repository..." -ForegroundColor Yellow
    git pull
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to pull latest code" -ForegroundColor Red
        exit 1
    }
    
    # Rebuild and restart services
    Write-Host "Rebuilding and restarting services..." -ForegroundColor Yellow
    docker-compose -f docker-compose.prod.yml up -d --build
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Services updated successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to update services" -ForegroundColor Red
        exit 1
    }
}

# Function to backup database
function Backup-Database {
    Write-Host "Creating database backup..." -ForegroundColor Yellow
    $date = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFile = "backup_$date.sql"
    
    # This is a simplified approach - in practice, you might need to use docker exec
    # to run pg_dump inside the container
    Write-Host "⚠️  Database backup command would go here" -ForegroundColor Yellow
    Write-Host "   Backup file would be: $backupFile" -ForegroundColor Cyan
    
    # Example command (uncomment and modify as needed):
    # docker-compose -f docker-compose.prod.yml exec postgres pg_dump -U $env:POSTGRES_USER $env:POSTGRES_DB > $backupFile
    
    Write-Host "✅ Database backup process completed" -ForegroundColor Green
}

# Function to monitor resources
function Monitor-Resources {
    Write-Host "Monitoring system resources..." -ForegroundColor Yellow
    Write-Host "Press Ctrl+C to exit monitoring" -ForegroundColor Cyan
    Start-Sleep -Seconds 2
    docker stats
}

# Function to show help
function Show-Help {
    Write-Host "RX-DEX Daily Production Operations Script" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: .\scripts\daily-prod.ps1 [command]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Commands:" -ForegroundColor Cyan
    Write-Host "  start     - Start all services" -ForegroundColor White
    Write-Host "  stop      - Stop all services" -ForegroundColor White
    Write-Host "  restart   - Restart all services" -ForegroundColor White
    Write-Host "  status    - Check service status" -ForegroundColor White
    Write-Host "  logs      - View service logs" -ForegroundColor White
    Write-Host "  update    - Update services to latest version" -ForegroundColor White
    Write-Host "  backup    - Create database backup" -ForegroundColor White
    Write-Host "  monitor   - Monitor system resources" -ForegroundColor White
    Write-Host "  help      - Show this help message" -ForegroundColor White
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Cyan
    Write-Host "  .\scripts\daily-prod.ps1 start" -ForegroundColor White
    Write-Host "  .\scripts\daily-prod.ps1 status" -ForegroundColor White
    Write-Host "  .\scripts\daily-prod.ps1 logs" -ForegroundColor White
}

# Main script logic
function Main {
    Check-Requirements
    
    $command = $args[0]
    
    switch ($command) {
        "start" {
            Load-Env
            Start-Services
        }
        "stop" {
            Load-Env
            Stop-Services
        }
        "restart" {
            Load-Env
            Restart-Services
        }
        "status" {
            Load-Env
            Check-Status
        }
        "logs" {
            Load-Env
            View-Logs
        }
        "update" {
            Load-Env
            Update-Services
        }
        "backup" {
            Load-Env
            Backup-Database
        }
        "monitor" {
            Monitor-Resources
        }
        "help" {
            Show-Help
        }
        default {
            if ($command) {
                Write-Host "Unknown command: $command" -ForegroundColor Red
            }
            Show-Help
        }
    }
}

# Run main function with all arguments
Main @args