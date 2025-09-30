# Production Monitoring Script for RX-DEX
# This script provides comprehensive monitoring for the RX-DEX production environment

Write-Host "========================================"
Write-Host "  RX-DEX Production Monitoring"
Write-Host "========================================"
Write-Host ""

# Function to check if required files exist
function Check-Requirements {
    if (-not (Test-Path ".env.prod")) {
        Write-Host "❌ Error: .env.prod file not found!" -ForegroundColor Red
        exit 1
    }
    
    if (-not (Test-Path "docker-compose.prod.yml")) {
        Write-Host "❌ Error: docker-compose.prod.yml file not found!" -ForegroundColor Red
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
}

# Function to check service status
function Check-ServiceStatus {
    Write-Host "=== Service Status ===" -ForegroundColor Cyan
    docker-compose -f docker-compose.prod.yml ps
    Write-Host ""
}

# Function to check system resources
function Check-SystemResources {
    Write-Host "=== System Resources ===" -ForegroundColor Cyan
    Write-Host "CPU Usage:" -ForegroundColor Yellow
    # This is a simplified approach - in practice, you might use Get-Counter or other methods
    Write-Host "System metrics would be displayed here" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "Memory Usage:" -ForegroundColor Yellow
    $memory = Get-WmiObject -Class Win32_OperatingSystem
    $usedMemory = [math]::Round(($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / 1MB, 2)
    $totalMemory = [math]::Round($memory.TotalVisibleMemorySize / 1MB, 2)
    $freeMemory = [math]::Round($memory.FreePhysicalMemory / 1MB, 2)
    Write-Host "Used: $usedMemory GB, Free: $freeMemory GB, Total: $totalMemory GB" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "Disk Usage:" -ForegroundColor Yellow
    $disk = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'"
    $usedDisk = [math]::Round((($disk.Size - $disk.FreeSpace) / 1GB), 2)
    $freeDisk = [math]::Round(($disk.FreeSpace / 1GB), 2)
    $totalDisk = [math]::Round(($disk.Size / 1GB), 2)
    $diskPercent = [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 2)
    Write-Host "Used: $usedDisk GB, Available: $freeDisk GB, Total: $totalDisk GB, Usage: $diskPercent%" -ForegroundColor Gray
    Write-Host ""
}

# Function to check Docker resources
function Check-DockerResources {
    Write-Host "=== Docker Resources ===" -ForegroundColor Cyan
    Write-Host "Running Containers:" -ForegroundColor Yellow
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    Write-Host ""
    
    Write-Host "Container Resource Usage:" -ForegroundColor Yellow
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
    Write-Host ""
}

# Function to check database status
function Check-DatabaseStatus {
    Write-Host "=== Database Status ===" -ForegroundColor Cyan
    try {
        $dbStatus = docker-compose -f docker-compose.prod.yml exec postgres pg_isready 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ PostgreSQL: Running" -ForegroundColor Green
        } else {
            Write-Host "❌ PostgreSQL: Not responding" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ PostgreSQL: Not responding" -ForegroundColor Red
    }
    
    # Check database size (simplified)
    Write-Host "Database Size: Information would be displayed here" -ForegroundColor Gray
    Write-Host ""
}

# Function to check Redis status
function Check-RedisStatus {
    Write-Host "=== Redis Status ===" -ForegroundColor Cyan
    try {
        $redisStatus = docker-compose -f docker-compose.prod.yml exec redis redis-cli ping 2>$null
        if ($redisStatus -eq "PONG") {
            Write-Host "✅ Redis: Running" -ForegroundColor Green
        } else {
            Write-Host "❌ Redis: Not responding" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Redis: Not responding" -ForegroundColor Red
    }
    
    Write-Host "Connected Clients: Information would be displayed here" -ForegroundColor Gray
    Write-Host ""
}

# Function to check API gateway health
function Check-ApiHealth {
    Write-Host "=== API Health Check ===" -ForegroundColor Cyan
    try {
        $apiStatus = Invoke-WebRequest -Uri "http://localhost:8080/health" -TimeoutSec 5 -ErrorAction Stop
        if ($apiStatus.StatusCode -eq 200) {
            Write-Host "✅ API Gateway: OK" -ForegroundColor Green
        } else {
            Write-Host "❌ API Gateway: Not responding" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ API Gateway: Not responding" -ForegroundColor Red
    }
    
    try {
        $webStatus = Invoke-WebRequest -Uri "http://localhost:8082" -TimeoutSec 5 -ErrorAction Stop
        if ($webStatus.StatusCode -eq 200) {
            Write-Host "✅ Web Frontend: OK" -ForegroundColor Green
        } else {
            Write-Host "❌ Web Frontend: Not responding" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Web Frontend: Not responding" -ForegroundColor Red
    }
    Write-Host ""
}

# Function to generate monitoring report
function Generate-Report {
    Write-Host "=== Monitoring Report Summary ===" -ForegroundColor Cyan
    $timestamp = Get-Date
    Write-Host "Report generated at: $timestamp" -ForegroundColor Gray
    Write-Host ""
    
    # Count running services
    $servicesOutput = docker-compose -f docker-compose.prod.yml ps
    $runningServices = ($servicesOutput | Select-String "Up").Count
    $totalServices = ($servicesOutput | Measure-Object).Count - 2 # Subtract header lines
    
    Write-Host "Services: $runningServices/$totalServices running" -ForegroundColor Gray
    
    # Check system load (simplified)
    $cpuUsage = Get-WmiObject -Class Win32_Processor | Measure-Object -Property LoadPercentage -Average | Select-Object Average
    Write-Host "System Load: $($cpuUsage.Average)%" -ForegroundColor Gray
    
    # Check memory usage percentage
    $memory = Get-WmiObject -Class Win32_OperatingSystem
    $memUsagePercent = [math]::Round((($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / $memory.TotalVisibleMemorySize) * 100, 2)
    Write-Host "Memory Usage: $memUsagePercent%" -ForegroundColor Gray
    
    # Check disk usage percentage
    $disk = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'"
    $diskPercent = [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 2)
    if ($diskPercent -gt 90) {
        Write-Host "⚠️  Disk Usage: $diskPercent% (High)" -ForegroundColor Yellow
    } elseif ($diskPercent -gt 75) {
        Write-Host "⚠️  Disk Usage: $diskPercent% (Medium)" -ForegroundColor Yellow
    } else {
        Write-Host "✅ Disk Usage: $diskPercent% (Normal)" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "=== End of Report ===" -ForegroundColor Cyan
}

# Function to show help
function Show-Help {
    Write-Host "RX-DEX Production Monitoring Script" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: .\scripts\monitor-prod.ps1 [option]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Cyan
    Write-Host "  all       - Run all monitoring checks (default)" -ForegroundColor White
    Write-Host "  status    - Check service status" -ForegroundColor White
    Write-Host "  resources - Check system and Docker resources" -ForegroundColor White
    Write-Host "  database  - Check database status" -ForegroundColor White
    Write-Host "  redis     - Check Redis status" -ForegroundColor White
    Write-Host "  api       - Check API health" -ForegroundColor White
    Write-Host "  report    - Generate monitoring report" -ForegroundColor White
    Write-Host "  help      - Show this help message" -ForegroundColor White
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Cyan
    Write-Host "  .\scripts\monitor-prod.ps1" -ForegroundColor White
    Write-Host "  .\scripts\monitor-prod.ps1 status" -ForegroundColor White
    Write-Host "  .\scripts\monitor-prod.ps1 report" -ForegroundColor White
}

# Main script logic
function Main {
    Check-Requirements
    Load-Env
    
    $option = $args[0]
    
    switch ($option) {
        "status" {
            Check-ServiceStatus
        }
        "resources" {
            Check-SystemResources
            Check-DockerResources
        }
        "database" {
            Check-DatabaseStatus
        }
        "redis" {
            Check-RedisStatus
        }
        "api" {
            Check-ApiHealth
        }
        "report" {
            Generate-Report
        }
        "help" {
            Show-Help
        }
        default {
            if (-not $option) {
                Check-ServiceStatus
                Check-SystemResources
                Check-DockerResources
                Check-DatabaseStatus
                Check-RedisStatus
                Check-ApiHealth
                Generate-Report
            } else {
                Write-Host "Unknown option: $option" -ForegroundColor Red
                Show-Help
            }
        }
    }
}

# Run main function with all arguments
Main @args