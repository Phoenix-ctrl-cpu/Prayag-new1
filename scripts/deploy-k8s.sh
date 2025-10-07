#!/bin/bash

# Kubernetes Deployment Script
# Usage: ./deploy-k8s.sh [environment] [image-tag]

set -e

ENVIRONMENT=${1:-production}
IMAGE_TAG=${2:-latest}
NAMESPACE="prayag-app"

echo "🚀 Starting deployment to Kubernetes..."
echo "Environment: $ENVIRONMENT"
echo "Image Tag: $IMAGE_TAG"
echo "Namespace: $NAMESPACE"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed or not in PATH"
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster"
    exit 1
fi

# Create namespace if it doesn't exist
echo "📦 Creating namespace if not exists..."
kubectl apply -f k8s/namespace.yaml

# Apply ConfigMap
echo "⚙️  Applying configuration..."
kubectl apply -f k8s/configmap.yaml

# Update image tag in deployment
echo "🔄 Updating deployment with image tag: $IMAGE_TAG"
sed "s|prayag8tiwari/prayag-new1-pipeline:latest|prayag8tiwari/prayag-new1-pipeline:$IMAGE_TAG|g" k8s/deployment.yaml | kubectl apply -f -

# Apply service
echo "🌐 Applying service..."
kubectl apply -f k8s/service.yaml

# Apply ingress (optional)
echo "🔗 Applying ingress..."
kubectl apply -f k8s/ingress.yaml

# Apply HPA
echo "📈 Applying horizontal pod autoscaler..."
kubectl apply -f k8s/hpa.yaml

# Wait for deployment to be ready
echo "⏳ Waiting for deployment to be ready..."
kubectl rollout status deployment/prayag-app-deployment -n $NAMESPACE --timeout=300s

# Get service information
echo "✅ Deployment completed!"
echo "📊 Service information:"
kubectl get services -n $NAMESPACE
echo ""
echo "🔍 Pod status:"
kubectl get pods -n $NAMESPACE
echo ""
echo "🌐 Ingress information:"
kubectl get ingress -n $NAMESPACE

# Get external IP if available
EXTERNAL_IP=$(kubectl get service prayag-app-service -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [ ! -z "$EXTERNAL_IP" ]; then
    echo "🌍 Application is accessible at: http://$EXTERNAL_IP"
else
    echo "ℹ️  External IP not available. Check your LoadBalancer configuration."
fi