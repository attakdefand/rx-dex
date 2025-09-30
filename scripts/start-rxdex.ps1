# Start RX-DEX services
Write-Host "Starting RX-DEX services..." -ForegroundColor Green

# Start services with docker-compose
docker-compose -f docker-compose.dev.yml up -d

# Wait a few seconds for services to start
Start-Sleep -Seconds 5

# Check status
Write-Host "Checking service status..." -ForegroundColor Yellow
docker-compose -f docker-compose.dev.yml ps

Write-Host "RX-DEX services started successfully!" -ForegroundColor Green
Write-Host "Services available at:" -ForegroundColor Cyan
Write-Host "  Web Frontend: http://localhost:8082" -ForegroundColor White
Write-Host "  API Gateway: http://localhost:8080" -ForegroundColor White
Write-Host "  Quoter Service: http://localhost:8081" -ForegroundColor White
Write-Host "  Order Service: http://localhost:8083" -ForegroundColor White
Write-Host "  User Service: http://localhost:8084" -ForegroundColor White
Write-Host "  Matching Engine: http://localhost:8085" -ForegroundColor White
Write-Host "  Wallet Service: http://localhost:8086" -ForegroundColor White
Write-Host "  Notification Service: http://localhost:8087" -ForegroundColor White
Write-Host "  Redis: localhost:6379" -ForegroundColor White
Write-Host "  PostgreSQL: localhost:5432" -ForegroundColor White