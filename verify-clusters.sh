#!/bin/bash

# Script to verify clusters in ArgoCD

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== ArgoCD Cluster Verification ===${NC}"
echo ""

# Check if we're connected to a cluster
if ! kubectl cluster-info >/dev/null 2>&1; then
    echo -e "${RED}Error: Not connected to any Kubernetes cluster${NC}"
    exit 1
fi

# Check ArgoCD status
echo -e "${BLUE}Checking ArgoCD status...${NC}"
if kubectl get pods -n argocd | grep -q "argocd-server.*Running"; then
    echo -e "${GREEN}✓ ArgoCD is running${NC}"
else
    echo -e "${RED}✗ ArgoCD server is not running${NC}"
    echo "Please check your ArgoCD installation"
    exit 1
fi

# Setup port forwarding
echo -e "${BLUE}Setting up port forwarding...${NC}"
kubectl port-forward svc/argocd-server -n argocd 8080:443 &
PORT_FORWARD_PID=$!

# Wait for port forwarding
sleep 5

# Get ArgoCD admin password
echo -e "${BLUE}Getting ArgoCD admin password...${NC}"
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 2>/dev/null)

if [ -z "$ARGOCD_PASSWORD" ]; then
    echo -e "${RED}✗ Could not retrieve ArgoCD admin password${NC}"
    kill $PORT_FORWARD_PID 2>/dev/null
    exit 1
fi

# Login to ArgoCD
echo -e "${BLUE}Logging into ArgoCD...${NC}"
argocd login localhost:8080 --username admin --password $ARGOCD_PASSWORD --insecure

echo -e "${GREEN}✓ Successfully connected to ArgoCD${NC}"
echo ""

# List clusters
echo -e "${BLUE}Clusters in ArgoCD:${NC}"
argocd cluster list
echo ""

# Check each cluster
echo -e "${BLUE}Checking cluster connectivity...${NC}"

# Get cluster list
CLUSTERS=$(argocd cluster list -o name | sed 's/cluster\.argoproj\.io\///')

for cluster in $CLUSTERS; do
    echo -e "${BLUE}Checking cluster: $cluster${NC}"
    if argocd cluster get $cluster >/dev/null 2>&1; then
        echo -e "${GREEN}✓ $cluster is accessible${NC}"
    else
        echo -e "${RED}✗ $cluster is not accessible${NC}"
    fi
done

# Cleanup
echo -e "${BLUE}Cleaning up...${NC}"
kill $PORT_FORWARD_PID 2>/dev/null || true

echo -e "${GREEN}✓ Verification complete!${NC}"