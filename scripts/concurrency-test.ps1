# Concurrency Testing Framework for RX-DEX
param(
    [int]$concurrentUsers = 1000,
    [int]$requestsPerUser = 100,
    [int]$durationMinutes = 5
)

Write-Host "Starting RX-DEX Concurrency Test..." -ForegroundColor Green
Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Concurrent Users: $concurrentUsers" -ForegroundColor White
Write-Host "  Requests per User: $requestsPerUser" -ForegroundColor White
Write-Host "  Test Duration: $durationMinutes minutes" -ForegroundColor White
Write-Host "  Total Requests: $($concurrentUsers * $requestsPerUser)" -ForegroundColor White

# Create test results directory
$testResultsDir = "test-results"
if (!(Test-Path $testResultsDir)) {
    New-Item -ItemType Directory -Path $testResultsDir | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$resultFile = "$testResultsDir\concurrency-test-$timestamp.txt"

# Write test info to result file
"RX-DEX Concurrency Test Results" | Out-File -FilePath $resultFile
"=============================" | Out-File -FilePath $resultFile -Append
"Start Time: $(Get-Date)" | Out-File -FilePath $resultFile -Append
"Concurrent Users: $concurrentUsers" | Out-File -FilePath $resultFile -Append
"Requests per User: $requestsPerUser" | Out-File -FilePath $resultFile -Append
"Test Duration: $durationMinutes minutes" | Out-File -FilePath $resultFile -Append
"Total Requests: $($concurrentUsers * $requestsPerUser)" | Out-File -FilePath $resultFile -Append
"" | Out-File -FilePath $resultFile -Append

# Function to simulate a user
function Simulate-User {
    param($userId, $requests)
    
    $successCount = 0
    $failureCount = 0
    $totalLatency = 0
    
    for ($i = 0; $i -lt $requests; $i++) {
        try {
            $startTime = Get-Date
            $response = Invoke-WebRequest -Uri "http://localhost:8081/quote/simple" -UseBasicParsing -TimeoutSec 10
            $endTime = Get-Date
            $latency = ($endTime - $startTime).TotalMilliseconds
            
            if ($response.StatusCode -eq 200) {
                $successCount++
            } else {
                $failureCount++
            }
            
            $totalLatency += $latency
        } catch {
            $failureCount++
        }
        
        # Small delay to simulate realistic user behavior
        Start-Sleep -Milliseconds (Get-Random -Minimum 10 -Maximum 100)
    }
    
    $avgLatency = if ($successCount -gt 0) { $totalLatency / $successCount } else { 0 }
    
    return @{
        UserId = $userId
        SuccessCount = $successCount
        FailureCount = $failureCount
        AverageLatency = $avgLatency
        TotalRequests = $requests
    }
}

# Start time
$testStartTime = Get-Date
Write-Host "Test started at: $testStartTime" -ForegroundColor Cyan

# Run concurrent users using background jobs
$jobs = @()
for ($i = 1; $i -le $concurrentUsers; $i++) {
    $job = Start-Job -ScriptBlock {
        param($userId, $requests)
        function Simulate-User {
            param($userId, $requests)
            
            $successCount = 0
            $failureCount = 0
            $totalLatency = 0
            
            for ($i = 0; $i -lt $requests; $i++) {
                try {
                    $startTime = Get-Date
                    $response = Invoke-WebRequest -Uri "http://localhost:8081/quote/simple" -UseBasicParsing -TimeoutSec 10
                    $endTime = Get-Date
                    $latency = ($endTime - $startTime).TotalMilliseconds
                    
                    if ($response.StatusCode -eq 200) {
                        $successCount++
                    } else {
                        $failureCount++
                    }
                    
                    $totalLatency += $latency
                } catch {
                    $failureCount++
                }
                
                # Small delay to simulate realistic user behavior
                Start-Sleep -Milliseconds (Get-Random -Minimum 10 -Maximum 100)
            }
            
            $avgLatency = if ($successCount -gt 0) { $totalLatency / $successCount } else { 0 }
            
            return @{
                UserId = $userId
                SuccessCount = $successCount
                FailureCount = $failureCount
                AverageLatency = $avgLatency
                TotalRequests = $requests
            }
        }
        
        return Simulate-User -userId $userId -requests $requests
    } -ArgumentList $i, $requestsPerUser
    
    $jobs += $job
    
    # Progress indicator
    if ($i % 100 -eq 0) {
        Write-Host "Started $i users..." -ForegroundColor Yellow
    }
}

Write-Host "All $concurrentUsers users started. Waiting for completion..." -ForegroundColor Cyan

# Wait for all jobs to complete
$completedJobs = @()
foreach ($job in $jobs) {
    $completedJob = Wait-Job -Job $job
    $completedJobs += $completedJob
}

# Collect results
$results = @()
foreach ($job in $completedJobs) {
    $result = Receive-Job -Job $job
    $results += $result
    Remove-Job -Job $job
}

# Test end time
$testEndTime = Get-Date
$testDuration = $testEndTime - $testStartTime

# Calculate statistics
$totalSuccess = ($results | Measure-Object -Property SuccessCount -Sum).Sum
$totalFailure = ($results | Measure-Object -Property FailureCount -Sum).Sum
$totalRequests = ($results | Measure-Object -Property TotalRequests -Sum).Sum
$avgLatency = ($results | Measure-Object -Property AverageLatency -Average).Average
$maxLatency = ($results | Measure-Object -Property AverageLatency -Maximum).Maximum
$minLatency = ($results | Measure-Object -Property AverageLatency -Minimum).Minimum

$successRate = if ($totalRequests -gt 0) { [math]::Round(($totalSuccess / $totalRequests) * 100, 2) } else { 0 }
$requestRate = if ($testDuration.TotalSeconds -gt 0) { [math]::Round($totalRequests / $testDuration.TotalSeconds, 2) } else { 0 }

# Display results
Write-Host "Test completed at: $testEndTime" -ForegroundColor Green
Write-Host "Test Duration: $($testDuration.TotalSeconds) seconds" -ForegroundColor Cyan
Write-Host "" -ForegroundColor White
Write-Host "=== TEST RESULTS ===" -ForegroundColor Green
Write-Host "Total Requests: $totalRequests" -ForegroundColor White
Write-Host "Successful Requests: $totalSuccess" -ForegroundColor White
Write-Host "Failed Requests: $totalFailure" -ForegroundColor White
Write-Host "Success Rate: $successRate%" -ForegroundColor White
Write-Host "Average Latency: $([math]::Round($avgLatency, 2)) ms" -ForegroundColor White
Write-Host "Min Latency: $([math]::Round($minLatency, 2)) ms" -ForegroundColor White
Write-Host "Max Latency: $([math]::Round($maxLatency, 2)) ms" -ForegroundColor White
Write-Host "Request Rate: $requestRate requests/second" -ForegroundColor White

# Write results to file
"Test completed at: $testEndTime" | Out-File -FilePath $resultFile -Append
"Test Duration: $($testDuration.TotalSeconds) seconds" | Out-File -FilePath $resultFile -Append
"" | Out-File -FilePath $resultFile -Append
"=== TEST RESULTS ===" | Out-File -FilePath $resultFile -Append
"Total Requests: $totalRequests" | Out-File -FilePath $resultFile -Append
"Successful Requests: $totalSuccess" | Out-File -FilePath $resultFile -Append
"Failed Requests: $totalFailure" | Out-File -FilePath $resultFile -Append
"Success Rate: $successRate%" | Out-File -FilePath $resultFile -Append
"Average Latency: $([math]::Round($avgLatency, 2)) ms" | Out-File -FilePath $resultFile -Append
"Min Latency: $([math]::Round($minLatency, 2)) ms" | Out-File -FilePath $resultFile -Append
"Max Latency: $([math]::Round($maxLatency, 2)) ms" | Out-File -FilePath $resultFile -Append
"Request Rate: $requestRate requests/second" | Out-File -FilePath $resultFile -Append

Write-Host "Results saved to: $resultFile" -ForegroundColor Cyan

# Resource usage (if available)
try {
    $cpuUsage = (Get-WmiObject -Class Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
    $memoryUsage = (Get-WmiObject -Class Win32_OperatingSystem | Select-Object @{Name="MemoryUsage";Expression={"{0:N2}" -f ((($_.TotalVisibleMemorySize - $_.FreePhysicalMemory) / $_.TotalVisibleMemorySize) * 100)}}).MemoryUsage
    
    Write-Host "CPU Usage: $cpuUsage%" -ForegroundColor White
    Write-Host "Memory Usage: $memoryUsage%" -ForegroundColor White
    
    "CPU Usage: $cpuUsage%" | Out-File -FilePath $resultFile -Append
    "Memory Usage: $memoryUsage%" | Out-File -FilePath $resultFile -Append
} catch {
    Write-Host "Could not retrieve system resource usage" -ForegroundColor Yellow
}