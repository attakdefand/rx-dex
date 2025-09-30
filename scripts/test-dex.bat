@echo off
REM RX-DEX Test Script for Windows
REM This script tests the complete DEX platform

echo Testing RX-DEX Platform...

REM Check if docker is installed
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Docker is not installed. Please install Docker Desktop first.
    pause
    exit /b 1
)

REM Navigate to the rx-dex directory
cd /d "%~dp0..\"

REM Start services in detached mode
echo Starting services...
docker-compose up -d

REM Wait for services to start
echo Waiting for services to start...
timeout /t 30 /nobreak >nul

REM Test API Gateway
echo Testing API Gateway...
curl -f http://localhost:8080/health >nul 2>&1
if %errorlevel% equ 0 (
    echo API Gateway is responding correctly
) else (
    echo API Gateway is not responding
)

REM Test Trading Service Endpoints
echo Testing Trading Service...
curl -f http://localhost:8080/api/market/overview >nul 2>&1
if %errorlevel% equ 0 (
    echo Market overview endpoint is responding correctly
) else (
    echo Market overview endpoint is not responding
)

curl -f http://localhost:8080/api/market/orderbook >nul 2>&1
if %errorlevel% equ 0 (
    echo Order book endpoint is responding correctly
) else (
    echo Order book endpoint is not responding
)

REM Test Quoter Service
echo Testing Quoter Service...
curl -f http://localhost:8080/api/quote/simple >nul 2>&1
if %errorlevel% equ 0 (
    echo Quoter service is responding correctly
) else (
    echo Quoter service is not responding
)

REM Test Web Frontend
echo Testing Web Frontend...
curl -f http://localhost:8082/ >nul 2>&1
if %errorlevel% equ 0 (
    echo Web frontend is responding correctly
) else (
    echo Web frontend is not responding
)

echo Test completed. Check the output above for any errors.
echo You can access the DEX at: http://localhost:8082

pause