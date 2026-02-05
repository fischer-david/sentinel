#!/bin/bash

echo "Building and deploying Sentinel plugin..."
echo "======================================"

cd "$(dirname "$0")"

echo "Running Maven build..."
mvn clean package -DskipTests

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Build and deployment completed successfully!"
    echo ""
    echo "The plugin has been:"
    echo "  • Built and packaged"
    echo "  • Copied to Paper plugins directory"
    echo "  • Copied to Velocity plugins directory"
    echo "  • Docker services (Paper and Velocity) have been restarted"
    echo ""
    echo "You can now test your changes on the development servers."
else
    echo ""
    echo "✗ Build failed! Please check the output above for errors."
    exit 1
fi
