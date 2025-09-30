@echo off
REM RX-DEX Start Script for Windows
REM This script starts the complete DEX platform

echo Starting RX-DEX Platform...

REM Check if docker is installed
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Docker is not installed. Please install Docker Desktop first.
    pause
    exit /b 1
)

REM Navigate to the rx-dex directory
cd /d "%~dp0..\"

REM Build and start all services
echo Building and starting all services...
docker-compose up --build -d

REM Wait for services to start
echo Waiting for services to start...
timeout /t 30 /nobreak >nul

REM Check if services are running
echo Checking service status...
docker-compose ps

echo RX-DEX Platform is now running!
echo Access the web interface at: http://localhost:8082
echo Access the API at: http://localhost:8080

pause