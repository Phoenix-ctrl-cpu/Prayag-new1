#!/bin/bash

# Configure Multi-Cluster ArgoCD Setup
# This script configures ArgoCD to manage multiple clusters

set -e

echo "⚙️  Configuring Multi-Cluster ArgoCD..."

# Switch to management cluster
kubectl config use-context argocd-mgmt

# Wait for ArgoCD to be ready
echo "⏳ Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Get ArgoCD server IP
ARGOCD_SERVER=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [ -z "$ARGOCD_SERVER" ]; then
    ARGOCD_SERVER="localhost"
fi

# Login to ArgoCD
echo "🔐 Logging into ArgoCD..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
argocd login $ARGOCD_SERVER --username admin --password $ARGOCD_PASSWORD --insecure

# Add remote clusters
add_cluster() {
    local cluster_name=$1
    local context_name=$2
    local server_url=$3
    
    echo "➕ Adding cluster: $cluster_name"
    
    # Get kubeconfig for the cluster
    kubectl config view --raw --minify --flatten -o json --context $context_name > /tmp/$cluster_name-kubeconfig.json
    
    # Add cluster to ArgoCD
    argocd cluster add $context_name --name $cluster_name --kubeconfig /tmp/$cluster_name-kubeconfig.json --yes
    
    echo "✅ Cluster $cluster_name added successfully"
}

# Add all clusters
add_cluster "dev" "argocd-dev" "https://argocd-dev-control-plane:6443"
add_cluster "qa" "argocd-qa" "https://argocd-qa-control-plane:6443"
add_cluster "prod" "argocd-prod" "https://argocd-prod-control-plane:6443"

# List clusters
echo "📋 Available clusters:"
argocd cluster list

# Create namespaces on each cluster
create_namespaces() {
    local cluster_name=$1
    local context_name=$2
    
    echo "📦 Creating namespaces on $cluster_name cluster..."
    
    kubectl config use-context $context_name
    
    # Create application namespace
    kubectl create namespace prayag-app --dry-run=client -o yaml | kubectl apply -f -
    
    # Create monitoring namespace
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    
    echo "✅ Namespaces created on $cluster_name"
}

# Create namespaces on all clusters
create_namespaces "dev" "argocd-dev"
create_namespaces "qa" "argocd-qa"
create_namespaces "prod" "argocd-prod"

# Switch back to management cluster
kubectl config use-context argocd-mgmt

echo "🎉 Multi-cluster configuration completed!"
echo ""
echo "📋 Next steps:"
echo "1. Run ./setup-gitops.sh to configure GitOps repository"
echo "2. Access ArgoCD UI at https://localhost:8080"
echo "3. You should see all 4 clusters (mgmt, dev, qa, prod) in the clusters section"