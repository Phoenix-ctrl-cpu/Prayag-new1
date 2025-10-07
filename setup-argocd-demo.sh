#!/bin/bash

# Complete ArgoCD Multi-Cluster Demo Setup Script
# This script sets up the entire ArgoCD demo environment

set -e

echo "🎭 ArgoCD Multi-Cluster Demo Setup"
echo "=================================="
echo ""

# Check prerequisites
check_prerequisites() {
    echo "🔍 Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        echo "❌ Docker is not running. Please start Docker first."
        exit 1
    fi
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        echo "❌ kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    
    # Check available memory
    TOTAL_MEM=$(free -g | awk '/^Mem:/{print $2}')
    if [ "$TOTAL_MEM" -lt 8 ]; then
        echo "⚠️  Warning: Less than 8GB RAM available. Demo may run slowly."
        echo "   Available: ${TOTAL_MEM}GB, Recommended: 8GB+"
        echo ""
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    echo "✅ Prerequisites check passed"
}

# Setup clusters
setup_clusters() {
    echo "🏗️  Setting up Kubernetes clusters..."
    cd clusters
    ./setup-clusters.sh
    cd ..
    echo "✅ Clusters setup completed"
}

# Configure clusters
configure_clusters() {
    echo "⚙️  Configuring multi-cluster setup..."
    cd clusters
    ./configure-clusters.sh
    cd ..
    echo "✅ Multi-cluster configuration completed"
}

# Setup GitOps
setup_gitops() {
    echo "📁 Setting up GitOps repository..."
    cd gitops
    ./setup-gitops.sh
    cd ..
    echo "✅ GitOps setup completed"
}

# Deploy applications
deploy_applications() {
    echo "🚀 Deploying applications..."
    cd gitops
    ./deploy-applications.sh
    cd ..
    echo "✅ Applications deployed"
}

# Show access information
show_access_info() {
    echo "🌐 Access Information"
    echo "===================="
    echo ""
    echo "ArgoCD UI:"
    echo "  URL: https://localhost:8080"
    echo "  Username: admin"
    echo "  Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 2>/dev/null || echo 'Check cluster setup')"
    echo ""
    echo "Applications:"
    echo "  Dev:  http://localhost:30080"
    echo "  QA:   http://localhost:30081"
    echo "  Prod: http://localhost:30082"
    echo ""
    echo "Demo Script:"
    echo "  Run: ./demo/demo-scenarios.sh"
    echo ""
    echo "Documentation:"
    echo "  Read: ARGOCD-DEMO-GUIDE.md"
}

# Main execution
main() {
    echo "Starting ArgoCD Multi-Cluster Demo Setup..."
    echo "This will create 4 Kubernetes clusters and set up ArgoCD"
    echo ""
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Setup cancelled."
        exit 0
    fi
    
    check_prerequisites
    setup_clusters
    configure_clusters
    setup_gitops
    deploy_applications
    show_access_info
    
    echo "🎉 ArgoCD Multi-Cluster Demo Setup Completed!"
    echo ""
    echo "Next steps:"
    echo "1. Access ArgoCD UI at https://localhost:8080"
    echo "2. Run the demo script: ./demo/demo-scenarios.sh"
    echo "3. Read the documentation: ARGOCD-DEMO-GUIDE.md"
    echo ""
    echo "To clean up all clusters:"
    echo "kind delete cluster --name argocd-mgmt"
    echo "kind delete cluster --name argocd-dev"
    echo "kind delete cluster --name argocd-qa"
    echo "kind delete cluster --name argocd-prod"
}

main "$@"