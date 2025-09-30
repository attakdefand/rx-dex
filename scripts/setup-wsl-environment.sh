#!/bin/bash

# Setup RX-DEX environment in WSL (Kali Linux)
echo "Setting up RX-DEX environment in WSL (Kali Linux)..."

# Update package list
echo "Updating package list..."
sudo apt update

# Install required packages
echo "Installing required packages..."
sudo apt install -y \
    curl \
    wget \
    git \
    build-essential \
    pkg-config \
    libssl-dev \
    libclang-dev \
    cmake \
    protobuf-compiler

# Install Rust
echo "Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Source cargo environment
source "$HOME/.cargo/env"

# Add wasm32 target
echo "Adding wasm32 target..."
rustup target add wasm32-unknown-unknown

# Install cargo tools
echo "Installing cargo tools..."
cargo install trunk cargo-watch

# Install Docker CLI (for connecting to Docker Desktop)
echo "Installing Docker CLI..."
sudo apt install -y docker.io

# Create symlink for Docker CLI to connect to Docker Desktop
sudo mkdir -p /etc/docker
echo '{"hosts": ["tcp://localhost:2375"]}' | sudo tee /etc/docker/daemon.json

# Install wrk for load testing
echo "Installing wrk for load testing..."
sudo apt install -y wrk

# Install monitoring tools
echo "Installing monitoring tools..."
sudo apt install -y htop iotop iftop

echo "WSL environment setup completed!"
echo "Please restart your shell or run 'source ~/.bashrc' to load the new environment."