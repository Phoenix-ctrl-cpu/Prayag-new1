#!/bin/bash

# Multi-Cluster ArgoCD Setup Script
# This script creates 3 local Kubernetes clusters and sets up ArgoCD

set -e

echo "🚀 Starting Multi-Cluster ArgoCD Setup..."

# Check prerequisites
check_prerequisites() {
    echo "🔍 Checking prerequisites..."
    
    if ! command -v kind &> /dev/null; then
        echo "❌ kind is not installed. Installing kind..."
        curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
        chmod +x ./kind
        sudo mv ./kind /usr/local/bin/kind
    fi
    
    if ! command -v kubectl &> /dev/null; then
        echo "❌ kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    echo "✅ Prerequisites check passed"
}

# Create kind clusters
create_clusters() {
    echo "🏗️  Creating Kubernetes clusters..."
    
    # Create management cluster (where ArgoCD will run)
    echo "Creating management cluster..."
    kind create cluster --name argocd-mgmt --config=kind-mgmt-config.yaml
    
    # Create dev cluster
    echo "Creating dev cluster..."
    kind create cluster --name argocd-dev --config=kind-dev-config.yaml
    
    # Create qa cluster
    echo "Creating qa cluster..."
    kind create cluster --name argocd-qa --config=kind-qa-config.yaml
    
    # Create prod cluster
    echo "Creating prod cluster..."
    kind create cluster --name argocd-prod --config=kind-prod-config.yaml
    
    echo "✅ All clusters created successfully"
}

# Install ArgoCD on management cluster
install_argocd() {
    echo "📦 Installing ArgoCD on management cluster..."
    
    # Switch to management cluster
    kubectl config use-context kind-argocd-mgmt
    
    # Create ArgoCD namespace
    kubectl create namespace argocd
    
    # Install ArgoCD
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    # Wait for ArgoCD to be ready
    echo "⏳ Waiting for ArgoCD to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
    
    # Get ArgoCD admin password
    echo "🔑 ArgoCD admin password:"
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
    echo ""
    
    echo "✅ ArgoCD installed successfully"
}

# Configure cluster contexts
configure_contexts() {
    echo "⚙️  Configuring cluster contexts..."
    
    # Create context aliases
    kubectl config rename-context kind-argocd-mgmt argocd-mgmt
    kubectl config rename-context kind-argocd-dev argocd-dev
    kubectl config rename-context kind-argocd-qa argocd-qa
    kubectl config rename-context kind-argocd-prod argocd-prod
    
    echo "✅ Contexts configured"
}

# Install ArgoCD CLI
install_argocd_cli() {
    echo "📥 Installing ArgoCD CLI..."
    
    if ! command -v argocd &> /dev/null; then
        curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
        sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
        rm argocd-linux-amd64
    fi
    
    echo "✅ ArgoCD CLI installed"
}

# Setup port forwarding for ArgoCD UI
setup_port_forwarding() {
    echo "🌐 Setting up port forwarding for ArgoCD UI..."
    
    # Start port forwarding in background
    kubectl port-forward svc/argocd-server -n argocd 8080:443 &
    PORT_FORWARD_PID=$!
    
    echo "ArgoCD UI will be available at: https://localhost:8080"
    echo "Username: admin"
    echo "Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
    echo ""
    echo "Port forwarding PID: $PORT_FORWARD_PID"
    echo "To stop port forwarding: kill $PORT_FORWARD_PID"
}

# Main execution
main() {
    check_prerequisites
    create_clusters
    install_argocd
    configure_contexts
    install_argocd_cli
    setup_port_forwarding
    
    echo "🎉 Multi-Cluster ArgoCD setup completed!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Access ArgoCD UI at https://localhost:8080"
    echo "2. Login with admin credentials shown above"
    echo "3. Run ./configure-clusters.sh to add remote clusters"
    echo "4. Run ./setup-gitops.sh to configure GitOps repository"
}

main "$@"