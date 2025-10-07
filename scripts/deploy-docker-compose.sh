#!/bin/bash

# Docker Compose Deployment Script
# Usage: ./deploy-docker-compose.sh [environment] [image-tag]

set -e

ENVIRONMENT=${1:-production}
IMAGE_TAG=${2:-latest}

echo "🚀 Starting deployment with Docker Compose..."
echo "Environment: $ENVIRONMENT"
echo "Image Tag: $IMAGE_TAG"

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "❌ docker-compose is not installed or not in PATH"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "❌ Docker is not running"
    exit 1
fi

# Update image tag in docker-compose.yml
echo "🔄 Updating image tag to: $IMAGE_TAG"
sed -i "s|prayag8tiwari/prayag-new1-pipeline:latest|prayag8tiwari/prayag-new1-pipeline:$IMAGE_TAG|g" docker-compose.yml

# Pull latest images
echo "📥 Pulling latest images..."
docker-compose pull

# Stop existing containers
echo "🛑 Stopping existing containers..."
docker-compose down

# Start services
echo "🚀 Starting services..."
docker-compose up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to be healthy..."
sleep 30

# Check service health
echo "🔍 Checking service health..."
if docker-compose ps | grep -q "Up (healthy)"; then
    echo "✅ Services are healthy!"
else
    echo "⚠️  Some services may not be healthy. Check logs:"
    docker-compose logs
fi

# Display service information
echo "📊 Service status:"
docker-compose ps

echo "🌐 Application is accessible at:"
echo "  - Direct: http://localhost:8080"
echo "  - Through Nginx: http://localhost:80"
echo "  - Prometheus: http://localhost:9090"
echo "  - Grafana: http://localhost:3000 (admin/admin)"