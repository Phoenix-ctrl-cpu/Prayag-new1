#!/bin/bash

# Quick start script for adding clusters to ArgoCD

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== ArgoCD Cluster Addition Quick Start ===${NC}"
echo ""

# Check if we're connected to a cluster
if ! kubectl cluster-info >/dev/null 2>&1; then
    echo -e "${YELLOW}Warning: Not connected to any Kubernetes cluster${NC}"
    echo "Please ensure you're connected to your dev cluster where ArgoCD is installed"
    echo ""
fi

# Check ArgoCD status
echo -e "${BLUE}Checking ArgoCD status...${NC}"
if kubectl get pods -n argocd | grep -q "argocd-server.*Running"; then
    echo -e "${GREEN}✓ ArgoCD is running${NC}"
else
    echo -e "${YELLOW}⚠ ArgoCD server is not running. Please check your ArgoCD installation.${NC}"
    echo "Run: kubectl get pods -n argocd"
    exit 1
fi

# Get ArgoCD admin password
echo -e "${BLUE}Getting ArgoCD admin password...${NC}"
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 2>/dev/null)

if [ -z "$ARGOCD_PASSWORD" ]; then
    echo -e "${YELLOW}⚠ Could not retrieve ArgoCD admin password${NC}"
    echo "Please check if ArgoCD is properly installed"
    exit 1
fi

echo -e "${GREEN}✓ ArgoCD admin password retrieved${NC}"
echo "Admin password: $ARGOCD_PASSWORD"
echo ""

# Setup port forwarding
echo -e "${BLUE}Setting up port forwarding...${NC}"
kubectl port-forward svc/argocd-server -n argocd 8080:443 &
PORT_FORWARD_PID=$!

# Wait for port forwarding
sleep 5

# Login to ArgoCD
echo -e "${BLUE}Logging into ArgoCD...${NC}"
argocd login localhost:8080 --username admin --password $ARGOCD_PASSWORD --insecure

echo -e "${GREEN}✓ Successfully connected to ArgoCD${NC}"
echo ""

# Show current clusters
echo -e "${BLUE}Current clusters in ArgoCD:${NC}"
argocd cluster list
echo ""

# Instructions for adding clusters
echo -e "${YELLOW}To add your main and prod clusters, you can:${NC}"
echo ""
echo "1. Using kubeconfig files:"
echo "   argocd cluster add main --kubeconfig /path/to/main-kubeconfig --server https://main-cluster:6443"
echo "   argocd cluster add prod --kubeconfig /path/to/prod-kubeconfig --server https://prod-cluster:6443"
echo ""
echo "2. Using kubectl contexts:"
echo "   kubectl config use-context main-cluster-context"
echo "   argocd cluster add main"
echo "   kubectl config use-context prod-cluster-context"
echo "   argocd cluster add prod"
echo ""

# Cleanup
echo -e "${BLUE}Cleaning up port forwarding...${NC}"
kill $PORT_FORWARD_PID 2>/dev/null || true

echo -e "${GREEN}✓ Setup complete!${NC}"
echo "You can now add your clusters using the commands above."