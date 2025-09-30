# Stop RX-DEX services
Write-Host "Stopping RX-DEX services..." -ForegroundColor Green

# Stop services with docker-compose
docker-compose -f docker-compose.dev.yml down

Write-Host "RX-DEX services stopped successfully!" -ForegroundColor Green