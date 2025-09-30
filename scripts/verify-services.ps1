# Verify RX-DEX Services
Write-Host "Verifying RX-DEX Services..." -ForegroundColor Green

# Test API Gateway
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080" -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ API Gateway: OK" -ForegroundColor Green
    } else {
        Write-Host "❌ API Gateway: Error (Status: $($response.StatusCode))" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ API Gateway: Not responding" -ForegroundColor Red
}

# Test Quoter Service
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8081/quote/simple" -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Quoter Service: OK" -ForegroundColor Green
        Write-Host "   Response: $($response.Content)" -ForegroundColor White
    } else {
        Write-Host "❌ Quoter Service: Error (Status: $($response.StatusCode))" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Quoter Service: Not responding" -ForegroundColor Red
}

# Test Order Service
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8083" -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Order Service: OK" -ForegroundColor Green
    } else {
        Write-Host "❌ Order Service: Error (Status: $($response.StatusCode))" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Order Service: Not responding" -ForegroundColor Red
}

# Test User Service
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8084" -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ User Service: OK" -ForegroundColor Green
    } else {
        Write-Host "❌ User Service: Error (Status: $($response.StatusCode))" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ User Service: Not responding" -ForegroundColor Red
}

# Test Matching Engine
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8085" -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Matching Engine: OK" -ForegroundColor Green
    } else {
        Write-Host "❌ Matching Engine: Error (Status: $($response.StatusCode))" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Matching Engine: Not responding" -ForegroundColor Red
}

# Test Wallet Service
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8086" -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Wallet Service: OK" -ForegroundColor Green
    } else {
        Write-Host "❌ Wallet Service: Error (Status: $($response.StatusCode))" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Wallet Service: Not responding" -ForegroundColor Red
}

# Test Notification Service
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8087" -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Notification Service: OK" -ForegroundColor Green
    } else {
        Write-Host "❌ Notification Service: Error (Status: $($response.StatusCode))" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Notification Service: Not responding" -ForegroundColor Red
}

# Test Redis
try {
    # This is a simple check - in a real scenario, you'd use a Redis client
    $tcp = New-Object System.Net.Sockets.TcpClient
    $tcp.Connect("localhost", 6379)
    if ($tcp.Connected) {
        Write-Host "✅ Redis: OK" -ForegroundColor Green
        $tcp.Close()
    } else {
        Write-Host "❌ Redis: Connection failed" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Redis: Not responding" -ForegroundColor Red
}

# Test PostgreSQL
try {
    # This is a simple check - in a real scenario, you'd use a PostgreSQL client
    $tcp = New-Object System.Net.Sockets.TcpClient
    $tcp.Connect("localhost", 5432)
    if ($tcp.Connected) {
        Write-Host "✅ PostgreSQL: OK" -ForegroundColor Green
        $tcp.Close()
    } else {
        Write-Host "❌ PostgreSQL: Connection failed" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ PostgreSQL: Not responding" -ForegroundColor Red
}

Write-Host "Service verification completed." -ForegroundColor Cyan