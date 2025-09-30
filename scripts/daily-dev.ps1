# Daily Development Workflow for RX-DEX
Write-Host "Starting RX-DEX Daily Development Workflow..." -ForegroundColor Green

# Start background jobs for each service
Write-Host "Starting QUOTER service..." -ForegroundColor Yellow
Start-Job { Set-Location "c:\Users\RMT\Documents\vscodium\crypto-Exchange-Rust-Base\RX-DEX\rx-dex"; cargo run -p quoter } -Name "quoter"

Write-Host "Starting API GATEWAY service..." -ForegroundColor Yellow
Start-Job { Set-Location "c:\Users\RMT\Documents\vscodium\crypto-Exchange-Rust-Base\RX-DEX\rx-dex"; cargo run -p api-gateway } -Name "api-gateway"

Write-Host "Starting ORDER SERVICE..." -ForegroundColor Yellow
Start-Job { Set-Location "c:\Users\RMT\Documents\vscodium\crypto-Exchange-Rust-Base\RX-DEX\rx-dex"; cargo run -p order-service } -Name "order-service"

Write-Host "Starting USER SERVICE..." -ForegroundColor Yellow
Start-Job { Set-Location "c:\Users\RMT\Documents\vscodium\crypto-Exchange-Rust-Base\RX-DEX\rx-dex"; cargo run -p user-service } -Name "user-service"

Write-Host "Starting MATCHING ENGINE..." -ForegroundColor Yellow
Start-Job { Set-Location "c:\Users\RMT\Documents\vscodium\crypto-Exchange-Rust-Base\RX-DEX\rx-dex"; cargo run -p matching-engine } -Name "matching-engine"

Write-Host "Starting WALLET SERVICE..." -ForegroundColor Yellow
Start-Job { Set-Location "c:\Users\RMT\Documents\vscodium\crypto-Exchange-Rust-Base\RX-DEX\rx-dex"; cargo run -p wallet-service } -Name "wallet-service"

Write-Host "Starting NOTIFICATION SERVICE..." -ForegroundColor Yellow
Start-Job { Set-Location "c:\Users\RMT\Documents\vscodium\crypto-Exchange-Rust-Base\RX-DEX\rx-dex"; cargo run -p notification-service } -Name "notification-service"

# Start web frontend in separate terminal/process
Write-Host "To start the web frontend, run in a separate terminal:" -ForegroundColor Cyan
Write-Host "  cd clients/web" -ForegroundColor White
Write-Host "  trunk serve --port 8082" -ForegroundColor White

Write-Host "All services started in background jobs!" -ForegroundColor Green
Write-Host "Use 'Get-Job' to see running jobs and 'Receive-Job -Name <jobname>' to see output" -ForegroundColor Cyan
Write-Host "Use 'Stop-Job -Name <jobname>' to stop a specific service" -ForegroundColor Cyan
Write-Host "Use 'Stop-Job -Name *' to stop all services" -ForegroundColor Cyan