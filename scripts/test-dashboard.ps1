# RX-DEX Testing Dashboard
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "        RX-DEX TESTING DASHBOARD" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# System Information
Write-Host "SYSTEM INFORMATION" -ForegroundColor Yellow
Write-Host "==================" -ForegroundColor Yellow
$cpuInfo = Get-WmiObject -Class Win32_Processor
$memoryInfo = Get-WmiObject -Class Win32_ComputerSystem
$osInfo = Get-WmiObject -Class Win32_OperatingSystem

Write-Host "CPU: $($cpuInfo.Name)" -ForegroundColor White
Write-Host "Cores: $($cpuInfo.NumberOfCores) | Logical Processors: $($cpuInfo.NumberOfLogicalProcessors)" -ForegroundColor White
Write-Host "Memory: $([math]::Round($memoryInfo.TotalPhysicalMemory / 1GB, 2)) GB" -ForegroundColor White
Write-Host "OS: $($osInfo.Caption) $($osInfo.Version)" -ForegroundColor White
Write-Host ""

# RX-DEX Status
Write-Host "RX-DEX STATUS" -ForegroundColor Yellow
Write-Host "=============" -ForegroundColor Yellow

try {
    # Check Docker services
    $dockerStatus = docker-compose -f docker-compose.dev.yml ps 2>$null
    if ($dockerStatus -match "Up") {
        Write-Host "Docker Services: RUNNING" -ForegroundColor Green
        # Count running services
        $runningServices = ($dockerStatus | Where-Object { $_ -match "Up" }).Count - 1  # Subtract header line
        Write-Host "Running Services: $runningServices" -ForegroundColor White
    } else {
        Write-Host "Docker Services: STOPPED" -ForegroundColor Red
    }
} catch {
    Write-Host "Docker Services: UNKNOWN (Docker may not be running)" -ForegroundColor Yellow
}

Write-Host ""

# Available Tests
Write-Host "AVAILABLE TESTS" -ForegroundColor Yellow
Write-Host "===============" -ForegroundColor Yellow
Write-Host "1. Health Check" -ForegroundColor White
Write-Host "   .\scripts\daily-health-check.ps1" -ForegroundColor DarkGray
Write-Host ""
Write-Host "2. Concurrency Test" -ForegroundColor White
Write-Host "   .\scripts\concurrency-test.ps1" -ForegroundColor DarkGray
Write-Host "   Parameters: -concurrentUsers <num> -requestsPerUser <num> -durationMinutes <num>" -ForegroundColor DarkGray
Write-Host ""
Write-Host "3. Load Test Suite" -ForegroundColor White
Write-Host "   .\scripts\load-test-suite.ps1" -ForegroundColor DarkGray
Write-Host "   Parameters: -testType <standard|stress|endurance>" -ForegroundColor DarkGray
Write-Host ""
Write-Host "4. Resource Monitoring" -ForegroundColor White
Write-Host "   .\scripts\monitor-resources.ps1" -ForegroundColor DarkGray
Write-Host "   Parameters: -durationSeconds <num> -intervalSeconds <num>" -ForegroundColor DarkGray
Write-Host ""

# Quick Actions
Write-Host "QUICK ACTIONS" -ForegroundColor Yellow
Write-Host "=============" -ForegroundColor Yellow
Write-Host "Start Development Services: .\scripts\start-rxdex.ps1" -ForegroundColor White
Write-Host "Stop Development Services:  .\scripts\stop-rxdex.ps1" -ForegroundColor White
Write-Host "Start Daily Dev Workflow:   .\scripts\daily-dev.ps1" -ForegroundColor White
Write-Host "Stop Daily Dev Workflow:    .\scripts\stop-daily-dev.ps1" -ForegroundColor White
Write-Host ""

Write-Host "For detailed instructions, see DOCKER-README.md" -ForegroundColor Cyan