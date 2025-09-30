# Install wrk for load testing
Write-Host "Installing wrk for load testing..." -ForegroundColor Green

# Check if Chocolatey is installed
if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Chocolatey not found. Installing Chocolatey first..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

# Install wrk using Chocolatey
choco install wrk -y

Write-Host "wrk installation completed!" -ForegroundColor Green
Write-Host "To run load tests, use:" -ForegroundColor Cyan
Write-Host "  wrk -t12 -c400 -d30s http://localhost:8081/quote/simple" -ForegroundColor White
Write-Host "This runs 12 threads with 400 concurrent connections for 30 seconds" -ForegroundColor White