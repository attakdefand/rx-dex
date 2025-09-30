#!/bin/bash

# Copy RX-DEX project to WSL
echo "Copying RX-DEX project to WSL..."

# Get the project directory (assuming script is run from rx-dex directory)
PROJECT_DIR=$(pwd)
PROJECT_NAME=$(basename "$PROJECT_DIR")

echo "Project directory: $PROJECT_DIR"
echo "Project name: $PROJECT_NAME"

# Create directory in WSL home if it doesn't exist
WSL_PROJECT_DIR="/home/$(whoami)/$PROJECT_NAME"
echo "WSL project directory: $WSL_PROJECT_DIR"

# Create the directory in WSL
wsl mkdir -p "$WSL_PROJECT_DIR"

# Copy files to WSL
echo "Copying files to WSL..."
wsl cp -r "$PROJECT_DIR"/* "$WSL_PROJECT_DIR"/

# Make scripts executable in WSL
echo "Making scripts executable..."
wsl find "$WSL_PROJECT_DIR/scripts" -name "*.sh" -exec chmod +x {} \;

echo "Project copied to WSL successfully!"
echo "To access the project in WSL, run:"
echo "  wsl cd ~/$PROJECT_NAME"