#!/bin/bash

# Script to add main and prod clusters to ArgoCD
# This script assumes ArgoCD is already installed on the dev cluster

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to wait for ArgoCD to be ready
wait_for_argocd() {
    local namespace=${1:-argocd}
    print_status "Waiting for ArgoCD to be ready in namespace: $namespace"
    
    # Wait for ArgoCD server to be ready
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n $namespace || {
        print_error "ArgoCD server is not ready. Please check the ArgoCD installation."
        exit 1
    }
    
    print_success "ArgoCD is ready!"
}

# Function to get ArgoCD admin password
get_argocd_password() {
    local namespace=${1:-argocd}
    print_status "Getting ArgoCD admin password..."
    
    # Get the admin password
    ARGOCD_PASSWORD=$(kubectl -n $namespace get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    
    if [ -z "$ARGOCD_PASSWORD" ]; then
        print_error "Could not retrieve ArgoCD admin password. Please check if ArgoCD is properly installed."
        exit 1
    fi
    
    print_success "ArgoCD admin password retrieved"
    echo "Admin password: $ARGOCD_PASSWORD"
}

# Function to login to ArgoCD
login_to_argocd() {
    local argocd_server=${1:-argocd-server}
    local namespace=${2:-argocd}
    
    print_status "Logging into ArgoCD..."
    
    # Port forward ArgoCD server
    print_status "Setting up port forwarding for ArgoCD server..."
    kubectl port-forward svc/$argocd_server -n $namespace 8080:443 &
    PORT_FORWARD_PID=$!
    
    # Wait a moment for port forwarding to establish
    sleep 5
    
    # Login to ArgoCD
    argocd login localhost:8080 --username admin --password $ARGOCD_PASSWORD --insecure || {
        print_error "Failed to login to ArgoCD"
        kill $PORT_FORWARD_PID 2>/dev/null
        exit 1
    }
    
    print_success "Successfully logged into ArgoCD"
}

# Function to add a cluster to ArgoCD
add_cluster_to_argocd() {
    local cluster_name=$1
    local cluster_server=$2
    local kubeconfig_path=$3
    
    print_status "Adding cluster '$cluster_name' to ArgoCD..."
    
    # Add cluster using kubeconfig
    argocd cluster add $cluster_name --kubeconfig $kubeconfig_path --yes || {
        print_error "Failed to add cluster '$cluster_name' to ArgoCD"
        return 1
    }
    
    print_success "Successfully added cluster '$cluster_name' to ArgoCD"
}

# Function to list clusters in ArgoCD
list_argocd_clusters() {
    print_status "Listing clusters in ArgoCD..."
    argocd cluster list
}

# Main execution
main() {
    print_status "Starting ArgoCD cluster addition process..."
    
    # Check if required commands exist
    if ! command_exists kubectl; then
        print_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    if ! command_exists argocd; then
        print_error "ArgoCD CLI is not installed or not in PATH"
        exit 1
    fi
    
    # Check if we're connected to a cluster
    if ! kubectl cluster-info >/dev/null 2>&1; then
        print_error "Not connected to any Kubernetes cluster. Please configure kubectl first."
        exit 1
    fi
    
    # Wait for ArgoCD to be ready
    wait_for_argocd
    
    # Get ArgoCD admin password
    get_argocd_password
    
    # Login to ArgoCD
    login_to_argocd
    
    # Add clusters (you'll need to provide the actual cluster details)
    print_warning "To add your clusters, you need to:"
    print_warning "1. Ensure you have kubeconfig files for main and prod clusters"
    print_warning "2. Update the cluster details in this script"
    print_warning "3. Run the add_cluster_to_argocd function for each cluster"
    
    # Example of how to add clusters (uncomment and modify as needed):
    # add_cluster_to_argocd "main" "https://main-cluster-server:6443" "/path/to/main-kubeconfig"
    # add_cluster_to_argocd "prod" "https://prod-cluster-server:6443" "/path/to/prod-kubeconfig"
    
    # List clusters
    list_argocd_clusters
    
    # Cleanup
    print_status "Cleaning up port forwarding..."
    kill $PORT_FORWARD_PID 2>/dev/null || true
    
    print_success "Process completed!"
}

# Run main function
main "$@"