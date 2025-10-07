#!/bin/bash

# Kubernetes Rollback Script
# Usage: ./rollback-k8s.sh [namespace]

set -e

NAMESPACE=${1:-prayag-app}

echo "🔄 Starting rollback process..."
echo "Namespace: $NAMESPACE"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed or not in PATH"
    exit 1
fi

# Get deployment history
echo "📋 Deployment history:"
kubectl rollout history deployment/prayag-app-deployment -n $NAMESPACE

# Rollback to previous version
echo "⏪ Rolling back to previous version..."
kubectl rollout undo deployment/prayag-app-deployment -n $NAMESPACE

# Wait for rollback to complete
echo "⏳ Waiting for rollback to complete..."
kubectl rollout status deployment/prayag-app-deployment -n $NAMESPACE --timeout=300s

echo "✅ Rollback completed!"
echo "📊 Current pod status:"
kubectl get pods -n $NAMESPACE