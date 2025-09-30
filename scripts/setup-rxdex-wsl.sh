#!/bin/bash

# Complete RX-DEX Setup for WSL (Kali Linux)
echo "========================================"
echo "  RX-DEX Complete WSL Setup Script"
echo "========================================"

# Check if we're in WSL
if ! grep -q microsoft /proc/version 2>/dev/null; then
    echo "Error: This script must be run in WSL"
    exit 1
fi

echo "Setting up RX-DEX in WSL (Kali Linux)..."

# Update package list
echo "1. Updating package list..."
sudo apt update

# Install required packages
echo "2. Installing required packages..."
sudo apt install -y \
    curl \
    wget \
    git \
    build-essential \
    pkg-config \
    libssl-dev \
    libclang-dev \
    cmake \
    protobuf-compiler \
    docker.io \
    wrk \
    htop \
    iotop \
    iftop

# Install Rust
echo "3. Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Source cargo environment
echo "4. Loading Rust environment..."
source "$HOME/.cargo/env"

# Add wasm32 target
echo "5. Adding wasm32 target..."
rustup target add wasm32-unknown-unknown

# Install cargo tools
echo "6. Installing cargo tools..."
cargo install trunk cargo-watch

# Make scripts executable
echo "7. Making scripts executable..."
find scripts -name "*.sh" -exec chmod +x {} \;

# Configure Docker CLI to connect to Docker Desktop
echo "8. Configuring Docker CLI..."
sudo mkdir -p /etc/docker
echo '{"hosts": ["tcp://localhost:2375"]}' | sudo tee /etc/docker/daemon.json

echo ""
echo "========================================"
echo "  RX-DEX WSL Setup Completed!"
echo "========================================"
echo ""
echo "Next steps:"
echo "1. Restart your shell or run: source ~/.bashrc"
echo "2. Start Docker Desktop on Windows"
echo "3. Run the daily development workflow: ./scripts/daily-dev-wsl.sh"
echo "4. In another terminal, start the web frontend: cd clients/web && trunk serve --port 8082"
echo ""
echo "To verify services are running:"
echo "  ./scripts/daily-health-check-wsl.sh"