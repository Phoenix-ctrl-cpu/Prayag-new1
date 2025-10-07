#!/bin/bash

# Specific script to add main and prod clusters to ArgoCD
# This script provides step-by-step instructions for adding clusters

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to add a cluster using kubeconfig file
add_cluster_with_kubeconfig() {
    local cluster_name=$1
    local kubeconfig_path=$2
    local cluster_server=$3
    
    print_status "Adding cluster '$cluster_name' using kubeconfig: $kubeconfig_path"
    
    # Validate kubeconfig file exists
    if [ ! -f "$kubeconfig_path" ]; then
        print_error "Kubeconfig file not found: $kubeconfig_path"
        return 1
    fi
    
    # Add cluster to ArgoCD
    argocd cluster add $cluster_name --kubeconfig $kubeconfig_path --server $cluster_server --yes || {
        print_error "Failed to add cluster '$cluster_name'"
        return 1
    }
    
    print_success "Successfully added cluster '$cluster_name'"
}

# Function to add a cluster using context name
add_cluster_with_context() {
    local cluster_name=$1
    local context_name=$2
    
    print_status "Adding cluster '$cluster_name' using context: $context_name"
    
    # Switch to the context
    kubectl config use-context $context_name || {
        print_error "Failed to switch to context: $context_name"
        return 1
    }
    
    # Add cluster to ArgoCD
    argocd cluster add $cluster_name --yes || {
        print_error "Failed to add cluster '$cluster_name'"
        return 1
    }
    
    print_success "Successfully added cluster '$cluster_name'"
}

# Function to setup ArgoCD connection
setup_argocd_connection() {
    local namespace=${1:-argocd}
    
    print_status "Setting up ArgoCD connection..."
    
    # Check if ArgoCD is running
    if ! kubectl get pods -n $namespace | grep -q "argocd-server.*Running"; then
        print_error "ArgoCD server is not running in namespace: $namespace"
        print_status "Please ensure ArgoCD is installed and running"
        return 1
    fi
    
    # Get admin password
    ARGOCD_PASSWORD=$(kubectl -n $namespace get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    
    if [ -z "$ARGOCD_PASSWORD" ]; then
        print_error "Could not retrieve ArgoCD admin password"
        return 1
    fi
    
    print_success "ArgoCD admin password retrieved"
    
    # Setup port forwarding
    print_status "Setting up port forwarding for ArgoCD server..."
    kubectl port-forward svc/argocd-server -n $namespace 8080:443 &
    PORT_FORWARD_PID=$!
    
    # Wait for port forwarding
    sleep 5
    
    # Login to ArgoCD
    argocd login localhost:8080 --username admin --password $ARGOCD_PASSWORD --insecure || {
        print_error "Failed to login to ArgoCD"
        kill $PORT_FORWARD_PID 2>/dev/null
        return 1
    }
    
    print_success "Successfully connected to ArgoCD"
    echo $PORT_FORWARD_PID
}

# Main function
main() {
    print_status "Starting cluster addition process..."
    
    # Setup ArgoCD connection
    PORT_FORWARD_PID=$(setup_argocd_connection)
    
    # Method 1: Using kubeconfig files
    print_status "Method 1: Using kubeconfig files"
    print_warning "If you have kubeconfig files for your clusters, place them in:"
    print_warning "  - /workspace/clusters/main/kubeconfig"
    print_warning "  - /workspace/clusters/prod/kubeconfig"
    print_warning "Then uncomment and run the following commands:"
    echo ""
    echo "# add_cluster_with_kubeconfig 'main' '/workspace/clusters/main/kubeconfig' 'https://main-cluster-server:6443'"
    echo "# add_cluster_with_kubeconfig 'prod' '/workspace/clusters/prod/kubeconfig' 'https://prod-cluster-server:6443'"
    echo ""
    
    # Method 2: Using kubectl contexts
    print_status "Method 2: Using kubectl contexts"
    print_warning "If you have kubectl contexts configured, you can use:"
    echo ""
    echo "# add_cluster_with_context 'main' 'main-cluster-context'"
    echo "# add_cluster_with_context 'prod' 'prod-cluster-context'"
    echo ""
    
    # Method 3: Manual addition
    print_status "Method 3: Manual addition using ArgoCD CLI"
    print_warning "You can also add clusters manually using:"
    echo ""
    echo "argocd cluster add <cluster-name> --kubeconfig <path-to-kubeconfig>"
    echo ""
    
    # List current clusters
    print_status "Current clusters in ArgoCD:"
    argocd cluster list
    
    # Cleanup
    print_status "Cleaning up..."
    kill $PORT_FORWARD_PID 2>/dev/null || true
    
    print_success "Setup complete! Please follow the instructions above to add your clusters."
}

# Run main function
main "$@"