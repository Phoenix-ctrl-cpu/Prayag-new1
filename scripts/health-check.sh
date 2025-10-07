#!/bin/bash

# Health Check Script
# Usage: ./health-check.sh [url] [timeout]

set -e

URL=${1:-http://localhost:8080}
TIMEOUT=${2:-30}

echo "🔍 Performing health check..."
echo "URL: $URL"
echo "Timeout: ${TIMEOUT}s"

# Function to check health
check_health() {
    local url=$1
    local timeout=$2
    
    if curl -f -s --max-time $timeout "$url" > /dev/null 2>&1; then
        echo "✅ Health check passed"
        return 0
    else
        echo "❌ Health check failed"
        return 1
    fi
}

# Perform health check
if check_health "$URL" "$TIMEOUT"; then
    echo "🎉 Application is healthy!"
    exit 0
else
    echo "💥 Application health check failed!"
    exit 1
fi