#!/bin/bash

# Test WSL Setup for RX-DEX
echo "Testing WSL Setup for RX-DEX..."

# Check if we're in WSL
if grep -q microsoft /proc/version 2>/dev/null; then
    echo "✅ Running in WSL"
else
    echo "❌ Not running in WSL"
    exit 1
fi

# Check if required commands are available
commands=("rustc" "cargo" "trunk" "docker" "wrk")
all_good=true

for cmd in "${commands[@]}"; do
    if command -v $cmd &> /dev/null; then
        echo "✅ $cmd: Available"
    else
        echo "❌ $cmd: Not found"
        all_good=false
    fi
done

# Check if project files exist
if [[ -f "Cargo.toml" ]]; then
    echo "✅ RX-DEX project files: Found"
else
    echo "❌ RX-DEX project files: Not found"
    echo "   Please run this script from the rx-dex directory"
    all_good=false
fi

# Check if scripts are executable
scripts=("daily-dev-wsl.sh" "stop-daily-dev-wsl.sh" "daily-health-check-wsl.sh")
for script in "${scripts[@]}"; do
    if [[ -f "scripts/$script" && -x "scripts/$script" ]]; then
        echo "✅ $script: Executable"
    else
        echo "❌ $script: Not executable"
        all_good=false
    fi
done

# Check Docker connectivity
echo "Checking Docker connectivity..."
if docker version &> /dev/null; then
    echo "✅ Docker: Connected"
else
    echo "❌ Docker: Connection failed"
    echo "   Make sure Docker Desktop is running on Windows"
    echo "   and configured to expose the daemon on tcp://localhost:2375"
    all_good=false
fi

# Check if Docker Compose files exist and are valid
compose_files=("docker-compose.yml" "docker-compose.wsl.yml")
for compose_file in "${compose_files[@]}"; do
    if [[ -f "$compose_file" ]]; then
        echo "✅ $compose_file: Found"
        # Test config
        if docker-compose -f "$compose_file" config &> /dev/null; then
            echo "✅ $compose_file: Valid configuration"
        else
            echo "❌ $compose_file: Invalid configuration"
            all_good=false
        fi
    else
        echo "❌ $compose_file: Not found"
        all_good=false
    fi
done

if $all_good; then
    echo ""
    echo "🎉 WSL setup verification completed successfully!"
    echo "You're ready to develop RX-DEX in WSL."
    echo ""
    echo "To start development:"
    echo "  Option 1 - Direct cargo execution:"
    echo "    ./scripts/daily-dev-wsl.sh"
    echo "    (In another terminal) cd clients/web && trunk serve --port 8082"
    echo ""
    echo "  Option 2 - Docker Compose:"
    echo "    docker-compose -f docker-compose.wsl.yml up --build"
else
    echo ""
    echo "⚠️  WSL setup verification found some issues."
    echo "Please check the output above and fix any missing components."
fi