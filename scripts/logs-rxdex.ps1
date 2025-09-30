param(
    [string]$service = ""
)

# View RX-DEX service logs
if ($service -eq "") {
    Write-Host "Viewing logs for all RX-DEX services..." -ForegroundColor Green
    docker-compose -f docker-compose.dev.yml logs -f
} else {
    Write-Host "Viewing logs for $service..." -ForegroundColor Green
    docker-compose -f docker-compose.dev.yml logs -f $service
}