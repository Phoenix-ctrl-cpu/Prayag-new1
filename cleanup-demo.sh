#!/bin/bash

# ArgoCD Demo Cleanup Script
# This script cleans up all demo resources

set -e

echo "🧹 Cleaning up ArgoCD Demo..."

# Function to delete cluster
delete_cluster() {
    local cluster_name=$1
    echo "🗑️  Deleting cluster: $cluster_name"
    if kind get clusters | grep -q "$cluster_name"; then
        kind delete cluster --name "$cluster_name"
        echo "✅ Cluster $cluster_name deleted"
    else
        echo "ℹ️  Cluster $cluster_name not found"
    fi
}

# Delete all clusters
echo "🗑️  Deleting all clusters..."
delete_cluster "argocd-mgmt"
delete_cluster "argocd-dev"
delete_cluster "argocd-qa"
delete_cluster "argocd-prod"

# Clean up local files
echo "🧹 Cleaning up local files..."
if [ -d "clusters" ]; then
    rm -rf clusters
    echo "✅ Clusters directory cleaned"
fi

if [ -d "gitops" ]; then
    rm -rf gitops
    echo "✅ GitOps directory cleaned"
fi

if [ -d "demo" ]; then
    rm -rf demo
    echo "✅ Demo directory cleaned"
fi

# Clean up any remaining kind clusters
echo "🧹 Cleaning up any remaining kind clusters..."
kind get clusters | xargs -I {} kind delete cluster --name {}

echo "🎉 ArgoCD Demo cleanup completed!"
echo ""
echo "All clusters and demo resources have been removed."
echo "You can now run ./setup-argocd-demo.sh to start fresh."