#!/bin/bash

# Deploy ArgoCD Applications Script
# This script deploys the ArgoCD applications to manage all environments

set -e

echo "🚀 Deploying ArgoCD Applications..."

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

# Deploy ArgoCD project
echo "📋 Deploying ArgoCD project..."
kubectl apply -f gitops/projects/prayag-project.yaml

# Deploy applications
deploy_application() {
    local app_name=$1
    local app_file=$2
    
    echo "📱 Deploying application: $app_name"
    kubectl apply -f $app_file
    
    # Wait for application to be synced
    echo "⏳ Waiting for $app_name to sync..."
    argocd app wait $app_name --timeout 300
    
    echo "✅ $app_name deployed successfully"
}

# Deploy all applications
deploy_application "prayag-app-dev" "gitops/applications/dev-app.yaml"
deploy_application "prayag-app-qa" "gitops/applications/qa-app.yaml"
deploy_application "prayag-app-prod" "gitops/applications/prod-app.yaml"

# List applications
echo "📋 Deployed applications:"
argocd app list

# Show application status
echo "📊 Application status:"
argocd app get prayag-app-dev
argocd app get prayag-app-qa
argocd app get prayag-app-prod

echo "🎉 All applications deployed successfully!"
echo ""
echo "🌐 Access points:"
echo "- ArgoCD UI: https://localhost:8080"
echo "- Dev App: http://localhost:30080"
echo "- QA App: http://localhost:30081"
echo "- Prod App: http://localhost:30082"