# Stop Daily Development Workflow for RX-DEX
Write-Host "Stopping RX-DEX Daily Development Workflow..." -ForegroundColor Green

# Stop all background jobs
Stop-Job -Name *

# Remove all jobs
Remove-Job -Name *

Write-Host "All services stopped!" -ForegroundColor Green