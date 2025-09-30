# Resource Monitoring Script for RX-DEX
param(
    [int]$durationSeconds = 60,
    [int]$intervalSeconds = 5
)

Write-Host "Starting Resource Monitoring..." -ForegroundColor Green
Write-Host "Duration: $durationSeconds seconds" -ForegroundColor Yellow
Write-Host "Interval: $intervalSeconds seconds" -ForegroundColor Yellow

# Create monitoring results directory
$monitorDir = "monitoring"
if (!(Test-Path $monitorDir)) {
    New-Item -ItemType Directory -Path $monitorDir | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$resultFile = "$monitorDir\resource-monitor-$timestamp.csv"

# Write CSV header
"Timestamp,CPU_Usage(%),Memory_Used(%),Memory_Used(GB),Memory_Total(GB),RX-DEX_Processes" | Out-File -FilePath $resultFile

$endTime = (Get-Date).AddSeconds($durationSeconds)
$counter = 0

while ((Get-Date) -lt $endTime) {
    $counter++
    $currentTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    try {
        # CPU Usage
        $cpuUsage = (Get-WmiObject -Class Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
        
        # Memory Usage
        $memory = Get-WmiObject -Class Win32_OperatingSystem
        $memoryTotalGB = [math]::Round($memory.TotalVisibleMemorySize / 1MB, 2)
        $memoryFreeGB = [math]::Round($memory.FreePhysicalMemory / 1MB, 2)
        $memoryUsedGB = [math]::Round(($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / 1MB, 2)
        $memoryUsagePercent = [math]::Round((($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / $memory.TotalVisibleMemorySize) * 100, 2)
        
        # Count RX-DEX processes
        $rxDexProcesses = (Get-Process | Where-Object { $_.ProcessName -like "*rx-dex*" -or $_.ProcessName -like "*rxdex*" }).Count
        
        # Display current values
        Write-Host "[$currentTime] CPU: $cpuUsage% | Memory: $memoryUsagePercent% ($memoryUsedGB GB / $memoryTotalGB GB) | RX-DEX Processes: $rxDexProcesses" -ForegroundColor White
        
        # Write to CSV
        "$currentTime,$cpuUsage,$memoryUsagePercent,$memoryUsedGB,$memoryTotalGB,$rxDexProcesses" | Out-File -FilePath $resultFile -Append
        
    } catch {
        Write-Host "[$currentTime] Error collecting metrics: $_" -ForegroundColor Red
        "$currentTime,Error,Error,Error,Error,Error" | Out-File -FilePath $resultFile -Append
    }
    
    Start-Sleep -Seconds $intervalSeconds
}

Write-Host "Resource monitoring completed!" -ForegroundColor Green
Write-Host "Results saved to: $resultFile" -ForegroundColor Cyan