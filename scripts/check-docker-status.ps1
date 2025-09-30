# Check Docker build status for RX-DEX
Write-Host "Checking RX-DEX Docker build status..." -ForegroundColor Green

# Check if containers are running
Write-Host "Running containers:" -ForegroundColor Yellow
docker-compose ps

# Check if images have been built
Write-Host "Built images:" -ForegroundColor Yellow
docker images | Select-String "rxdex"

Write-Host "Build process may still be ongoing. Please wait for it to complete." -ForegroundColor Cyan