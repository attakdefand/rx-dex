# Daily Health Check for RX-DEX
Write-Host "Performing RX-DEX Daily Health Check..." -ForegroundColor Green

# Check if services are responding
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/health" -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ API Gateway: OK" -ForegroundColor Green
    } else {
        Write-Host "❌ API Gateway: Error - Status $($response.StatusCode)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ API Gateway: Not responding" -ForegroundColor Red
}

try {
    $response = Invoke-WebRequest -Uri "http://localhost:8081/quote/simple" -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Quoter Service: OK" -ForegroundColor Green
    } else {
        Write-Host "❌ Quoter Service: Error - Status $($response.StatusCode)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Quoter Service: Not responding" -ForegroundColor Red
}

try {
    $response = Invoke-WebRequest -Uri "http://localhost:8082" -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Web Frontend: OK" -ForegroundColor Green
    } else {
        Write-Host "❌ Web Frontend: Error - Status $($response.StatusCode)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Web Frontend: Not responding" -ForegroundColor Red
}

Write-Host "Health check completed." -ForegroundColor Cyan