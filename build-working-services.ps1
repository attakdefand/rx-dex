# Script to build only the services that work with our current Docker setup
# These are the services that don't have dependency issues with edition 2024

Write-Host "Building working services..."

# Build services that work
docker-compose build quoter
docker-compose build api-gateway
docker-compose build user-service
docker-compose build wallet-service
docker-compose build notification-service
docker-compose build admin-service
docker-compose build indexer

Write-Host "Build process completed for working services."
Write-Host "The following services have dependency issues and were not built:"
Write-Host "- order-service"
Write-Host "- matching-engine"
Write-Host "- trading-service"
Write-Host "- web"