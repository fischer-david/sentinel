#!/bin/bash

# Deploy script for Sentinel Minecraft plugin
# This script copies the built JAR to plugin directories and restarts Docker services

echo "Starting deployment process..."

JAR_FILE="target/minecraft-1.0-SNAPSHOT.jar"
if [ ! -f "$JAR_FILE" ]; then
    echo "Error: JAR file not found at $JAR_FILE"
    echo "Please run 'mvn clean package' first"
    exit 1
fi

echo "Found JAR file: $JAR_FILE"

mkdir -p "../development/paper/plugins"
mkdir -p "../development/velocity/plugins"

echo "Copying plugin to Paper plugins directory..."
cp "$JAR_FILE" "../development/paper/plugins/sentinel-1.0-SNAPSHOT.jar"
if [ $? -eq 0 ]; then
    echo "✓ Successfully copied to Paper plugins"
else
    echo "✗ Failed to copy to Paper plugins"
    exit 1
fi

echo "Copying plugin to Velocity plugins directory..."
cp "$JAR_FILE" "../development/velocity/plugins/sentinel-1.0-SNAPSHOT.jar"
if [ $? -eq 0 ]; then
    echo "✓ Successfully copied to Velocity plugins"
else
    echo "✗ Failed to copy to Velocity plugins"
    exit 1
fi

cd ..

echo "Checking Docker Compose services status..."
if docker compose -f development/docker-compose.dev.yml -p sentinel ps | grep -q "Up"; then
    echo "Docker services are running, restarting paper and velocity..."

    echo "Restarting Paper service..."
    docker compose -f development/docker-compose.dev.yml -p sentinel restart paper
    if [ $? -eq 0 ]; then
        echo "✓ Paper service restarted successfully"
    else
        echo "✗ Failed to restart Paper service"
    fi

    echo "Restarting Velocity service..."
    docker compose -f development/docker-compose.dev.yml -p sentinel restart velocity
    if [ $? -eq 0 ]; then
        echo "✓ Velocity service restarted successfully"
    else
        echo "✗ Failed to restart Velocity service"
    fi

    echo "Deployment completed successfully!"
    echo ""
    echo "Plugin locations:"
    echo "  Paper: development/paper/plugins/sentinel-1.0-SNAPSHOT.jar"
    echo "  Velocity: development/velocity/plugins/sentinel-1.0-SNAPSHOT.jar"
else
    echo "Docker services are not running. Plugin files copied, but services not restarted."
    echo "To start services, run: npm run docker:up"
fi
