# Comprehensive Load Testing Suite for RX-DEX
param(
    [string]$testType = "standard"  # standard, stress, endurance
)

Write-Host "Starting RX-DEX Load Test Suite..." -ForegroundColor Green
Write-Host "Test Type: $testType" -ForegroundColor Yellow

# Create test results directory
$testResultsDir = "test-results"
if (!(Test-Path $testResultsDir)) {
    New-Item -ItemType Directory -Path $testResultsDir | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$resultFile = "$testResultsDir\load-test-$testType-$timestamp.txt"

# Write test info to result file
"RX-DEX Load Test Results - $testType" | Out-File -FilePath $resultFile
"=================================" | Out-File -FilePath $resultFile -Append
"Start Time: $(Get-Date)" | Out-File -FilePath $resultFile -Append
"Test Type: $testType" | Out-File -FilePath $resultFile -Append
"" | Out-File -FilePath $resultFile -Append

# Define test parameters based on test type
switch ($testType) {
    "standard" {
        $threadCount = 12
        $connectionCount = 400
        $duration = "30s"
        $description = "Standard load test"
    }
    "stress" {
        $threadCount = 36  # Use all cores
        $connectionCount = 2000
        $duration = "60s"
        $description = "High stress test"
    }
    "endurance" {
        $threadCount = 18
        $connectionCount = 1000
        $duration = "300s"  # 5 minutes
        $description = "Long duration endurance test"
    }
    default {
        $threadCount = 12
        $connectionCount = 400
        $duration = "30s"
        $description = "Standard load test"
    }
}

Write-Host "Test Configuration:" -ForegroundColor Cyan
Write-Host "  Description: $description" -ForegroundColor White
Write-Host "  Threads: $threadCount" -ForegroundColor White
Write-Host "  Connections: $connectionCount" -ForegroundColor White
Write-Host "  Duration: $duration" -ForegroundColor White

"description: $description" | Out-File -FilePath $resultFile -Append
"Threads: $threadCount" | Out-File -FilePath $resultFile -Append
"Connections: $connectionCount" | Out-File -FilePath $resultFile -Append
"Duration: $duration" | Out-File -FilePath $resultFile -Append
"" | Out-File -FilePath $resultFile -Append

# Check if wrk is installed
if (!(Get-Command wrk -ErrorAction SilentlyContinue)) {
    Write-Host "wrk not found. Please run .\scripts\install-wrk.ps1 first" -ForegroundColor Red
    exit 1
}

# Test endpoints
$endpoints = @(
    @{ name = "Quoter Service"; url = "http://localhost:8081/quote/simple" },
    @{ name = "API Gateway Health"; url = "http://localhost:8080/health" }
)

foreach ($endpoint in $endpoints) {
    Write-Host "Testing: $($endpoint.name)" -ForegroundColor Yellow
    Write-Host "URL: $($endpoint.url)" -ForegroundColor White
    
    "$($endpoint.name):" | Out-File -FilePath $resultFile -Append
    "URL: $($endpoint.url)" | Out-File -FilePath $resultFile -Append
    
    try {
        # Run wrk test
        $output = wrk -t$threadCount -c$connectionCount -d$duration $($endpoint.url) 2>&1
        
        # Display and save output
        Write-Host $output -ForegroundColor White
        $output | Out-File -FilePath $resultFile -Append
        
        # Parse key metrics
        $lines = $output -split "`n"
        foreach ($line in $lines) {
            if ($line -match "Requests/sec:") {
                $rps = $line -replace "Requests/sec:\s*", ""
                Write-Host "Requests/sec: $rps" -ForegroundColor Green
                "Requests/sec: $rps" | Out-File -FilePath $resultFile -Append
            }
            if ($line -match "Transfer/sec:") {
                $tps = $line -replace "Transfer/sec:\s*", ""
                Write-Host "Transfer/sec: $tps" -ForegroundColor Green
                "Transfer/sec: $tps" | Out-File -FilePath $resultFile -Append
            }
        }
    } catch {
        Write-Host "Error testing $($endpoint.name): $_" -ForegroundColor Red
        "Error: $_" | Out-File -FilePath $resultFile -Append
    }
    
    "" | Out-File -FilePath $resultFile -Append
}

Write-Host "Load test completed!" -ForegroundColor Green
Write-Host "Results saved to: $resultFile" -ForegroundColor Cyan

# Resource monitoring during test
Write-Host "Monitoring system resources..." -ForegroundColor Yellow

# Simple resource check
try {
    $cpu = (Get-WmiObject -Class Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
    $memory = Get-WmiObject -Class Win32_OperatingSystem
    $memoryUsage = [math]::Round((($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / $memory.TotalVisibleMemorySize) * 100, 2)
    
    Write-Host "CPU Usage: $cpu%" -ForegroundColor White
    Write-Host "Memory Usage: $memoryUsage%" -ForegroundColor White
    
    "System Resources:" | Out-File -FilePath $resultFile -Append
    "CPU Usage: $cpu%" | Out-File -FilePath $resultFile -Append
    "Memory Usage: $memoryUsage%" | Out-File -FilePath $resultFile -Append
} catch {
    Write-Host "Could not retrieve system resource usage" -ForegroundColor Yellow
}