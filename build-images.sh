#!/bin/bash

set -e

echo "🚀 Building Sentinel Docker Images..."

echo "📦 Building backend image..."
docker build -f backend/Dockerfile -t sentinel-backend:latest .

echo "🌐 Building webpanel image..."
docker build -f webpanel/Dockerfile -t sentinel-webpanel:latest .

echo "✅ All images built successfully!"